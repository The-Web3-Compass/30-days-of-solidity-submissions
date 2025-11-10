// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * AdvancedEscrowV1
 * ------------------------------------------------------------
 * Features
 * - ETH or ERC20 payment (address(0) => ETH)
 * - Milestones (bps must sum to 10000)
 * - Optional NFT collateral held in escrow
 * - Dispute flow with a single arbiter; hook for DAO arbitrator
 * - Penalty (bps/day) if seller delays beyond milestone deadline
 * - Auto-release milestone if buyer doesn’t respond within grace period
 * - Platform fee (bps) on each released amount
 * - Rating events for off-chain marketplace UX
 *
 * Notes
 * - Keep Foundry via-IR on for larger functions if you hit "stack too deep".
 * - To keep this file self-contained, minimal IERC20/IERC721 interfaces are included.
 */

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address f, address t, uint256 v) external returns (bool);
    function balanceOf(address a) external view returns (uint256);
    function allowance(address o, address s) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * Optional DAO arbitrator interface (plug in later).
 * If you integrate Kleros or a token-voting DAO, they can call `rule()`.
 */
interface IArbitratorHook {
    /**
     * @dev Arbitrator must call with the final ruling.
     * selector: rule(address escrow, bool releaseToSeller)
     */
    function rule(address escrow, bool releaseToSeller) external;
}

contract AdvancedEscrowV1 {
    // ---- Parties & assets -------------------------------------------------

    address public immutable buyer;
    address public immutable seller;
    address public arbiter;          // can be an EOA or a DAO-owned executor

    // paymentToken == address(0) => ETH; otherwise ERC20
    address public immutable paymentToken;
    uint256 public immutable totalAmount;

    // Optional NFT collateral (escrowed while active)
    address public immutable collateralNft;     // address(0) => none
    uint256 public immutable collateralTokenId; // 0 if none

    // ---- Fees & penalty ---------------------------------------------------

    address public feeRecipient; // platform
    uint16  public feeBps;       // 0..10000

    // Penalty on seller if late vs milestone deadline (per-day bps)
    uint16  public dailyPenaltyBps; // e.g., 100 = 1% per day on that milestone’s amount
    uint16  public maxPenaltyBps;   // cap across all days, e.g., 2000 = max 20%

    // ---- Milestones -------------------------------------------------------

    uint16[]  public milestoneBps;        // sums to 10000
    uint256[] public milestoneDeadlines;  // epoch seconds
    uint256   public currentMilestone;    // index of next milestone to release

    // ---- States & timers --------------------------------------------------

    enum State { AWAITING_DEPOSIT, ACTIVE, DISPUTED, COMPLETE, CANCELLED }
    State   public state;

    uint256 public depositTime;
    uint256 public buyerGracePeriod;   // auto-release if buyer silent

    // For each milestone, when seller marked delivered (starts buyer grace countdown)
    mapping(uint256 => uint256) public sellerMarkedAt;

    // ---- Events -----------------------------------------------------------

    event Deposited(address indexed payer, uint256 amount, address token);
    event MarkDelivered(uint256 indexed milestone, uint256 at);
    event Approved(uint256 indexed milestone, uint256 netToSeller, uint256 fee, uint256 penalty);
    event AutoReleased(uint256 indexed milestone, uint256 at);
    event DisputeRaised(address indexed by);
    event DisputeResolved(address indexed by, bool releaseToSeller);
    event Cancelled(address indexed by, uint256 refund);
    event CollateralLocked(address indexed nft, uint256 indexed tokenId);
    event CollateralReturned(address indexed nft, uint256 indexed tokenId);
    event Rated(address indexed rater, uint8 buyerRating, uint8 sellerRating, string meta);
    event FeeConfigUpdated(address feeTo, uint16 feeBps);
    event PenaltyConfigUpdated(uint16 dailyBps, uint16 maxBps);
    event ArbiterUpdated(address indexed oldArbiter, address indexed newArbiter);

    // ---- Modifiers --------------------------------------------------------

    modifier onlyBuyer()   { require(msg.sender == buyer,   "only buyer");   _; }
    modifier onlySeller()  { require(msg.sender == seller,  "only seller");  _; }
    modifier onlyArbiter() { require(msg.sender == arbiter, "only arbiter"); _; }
    modifier inState(State s) { require(state == s, "bad state"); _; }

    // ---- Constructor ------------------------------------------------------

    /**
     * @param _buyer            Buyer
     * @param _seller           Seller
     * @param _arbiter          Arbiter (DAO or EOA)
     * @param _paymentToken     address(0) => ETH, else ERC20
     * @param _totalAmount      Full escrow amount
     * @param _mBps             Milestones in basis points (sum=10000)
     * @param _mDeadlines       Epoch seconds for each milestone
     * @param _feeRecipient     Platform fee receiver
     * @param _feeBps           Platform fee bps (e.g. 200 = 2%)
     * @param _dailyPenaltyBps  Late penalty per day (bps)
     * @param _maxPenaltyBps    Max penalty cap (bps)
     * @param _buyerGracePeriod Seconds after seller marks delivered
     * @param _collateralNft    Optional NFT address (0 for none)
     * @param _collateralId     Optional tokenId (0 for none)
     */
    constructor(
        address _buyer,
        address _seller,
        address _arbiter,
        address _paymentToken,
        uint256 _totalAmount,
        uint16[] memory _mBps,
        uint256[] memory _mDeadlines,
        address _feeRecipient,
        uint16 _feeBps,
        uint16 _dailyPenaltyBps,
        uint16 _maxPenaltyBps,
        uint256 _buyerGracePeriod,
        address _collateralNft,
        uint256 _collateralId
    ) {
        require(_buyer != address(0) && _seller != address(0), "zero party");
        require(_totalAmount > 0, "amount=0");
        require(_mBps.length > 0 && _mBps.length == _mDeadlines.length, "bad milestones");

        uint256 sum;
        for (uint256 i; i < _mBps.length; i++) sum += _mBps[i];
        require(sum == 10000, "bps != 10000");

        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        paymentToken = _paymentToken;
        totalAmount = _totalAmount;

        feeRecipient = _feeRecipient;
        feeBps = _feeBps;

        dailyPenaltyBps = _dailyPenaltyBps;
        maxPenaltyBps = _maxPenaltyBps;

        buyerGracePeriod = _buyerGracePeriod;

        milestoneBps = _mBps;
        milestoneDeadlines = _mDeadlines;

        collateralNft = _collateralNft;
        collateralTokenId = _collateralId;

        state = State.AWAITING_DEPOSIT;
    }

    // ---- Views ------------------------------------------------------------

    function milestones() external view returns (uint16[] memory bps, uint256[] memory deadlines) {
        return (milestoneBps, milestoneDeadlines);
    }

    function milestonesCount() external view returns (uint256) {
        return milestoneBps.length;
    }

    function currentMilestoneAmount() public view returns (uint256) {
        require(currentMilestone < milestoneBps.length, "all done");
        return (totalAmount * milestoneBps[currentMilestone]) / 10000;
    }

    function getState() external view returns (State) {
        return state;
    }

    // ---- Admin-lite (safe tweaks) ----------------------------------------

    function setFeeConfig(address _feeRecipient, uint16 _feeBps) external onlyBuyer {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        emit FeeConfigUpdated(_feeRecipient, _feeBps);
    }

    function setPenaltyConfig(uint16 _dailyPenaltyBps, uint16 _maxPenaltyBps) external onlyBuyer {
        dailyPenaltyBps = _dailyPenaltyBps;
        maxPenaltyBps = _maxPenaltyBps;
        emit PenaltyConfigUpdated(_dailyPenaltyBps, _maxPenaltyBps);
    }

    function setArbiter(address _arbiter) external onlyBuyer {
        emit ArbiterUpdated(arbiter, _arbiter);
        arbiter = _arbiter;
    }

    // ---- Deposit flow -----------------------------------------------------

    /**
     * Buyer deposits the full amount (ETH or ERC20).
     * If NFT collateral is configured, it must already be approved, then we pull it.
     */
    function deposit() external payable onlyBuyer inState(State.AWAITING_DEPOSIT) {
        if (paymentToken == address(0)) {
            require(msg.value == totalAmount, "bad ETH amount");
        } else {
            require(msg.value == 0, "no ETH");
            // pull tokens
            require(IERC20(paymentToken).transferFrom(msg.sender, address(this), totalAmount), "erc20 xferFrom fail");
        }

        // Lock NFT collateral if configured
        if (collateralNft != address(0)) {
            IERC721(collateralNft).transferFrom(msg.sender, address(this), collateralTokenId);
            emit CollateralLocked(collateralNft, collateralTokenId);
        }

        depositTime = block.timestamp;
        state = State.ACTIVE;
        emit Deposited(msg.sender, totalAmount, paymentToken);
    }

    // ---- Seller marks delivered for current milestone ---------------------

    function markDelivered() external onlySeller inState(State.ACTIVE) {
        require(currentMilestone < milestoneBps.length, "done");
        require(sellerMarkedAt[currentMilestone] == 0, "already marked");
        sellerMarkedAt[currentMilestone] = block.timestamp;
        emit MarkDelivered(currentMilestone, block.timestamp);
    }

    // ---- Buyer approves current milestone --------------------------------

    function approveCurrentMilestone() external onlyBuyer inState(State.ACTIVE) {
        _releaseCurrentMilestone(false);
    }

    // ---- Auto-release if buyer silent past grace period -------------------

    function autoReleaseIfTimedOut() external inState(State.ACTIVE) {
        uint256 idx = currentMilestone;
        require(idx < milestoneBps.length, "done");
        uint256 markedAt = sellerMarkedAt[idx];
        require(markedAt != 0, "not marked");

        require(block.timestamp >= markedAt + buyerGracePeriod, "grace not over");
        _releaseCurrentMilestone(true);
        emit AutoReleased(idx, block.timestamp);
    }

    // ---- Dispute flow -----------------------------------------------------

    function raiseDispute() external inState(State.ACTIVE) {
        require(msg.sender == buyer || msg.sender == seller, "no auth");
        state = State.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    /**
     * Arbiter resolves: release to seller or refund to buyer (for remaining amount).
     * If partially completed milestones already paid, this only affects remaining path.
     */
    function resolveDispute(bool releaseToSeller) external onlyArbiter inState(State.DISPUTED) {
        _resolve(releaseToSeller);
        emit DisputeResolved(msg.sender, releaseToSeller);
    }

    /**
     * DAO hook can call into this (e.g., Kleros court integration).
     * The DAO contract should be set as `arbiter`.
     */
    function rule(address escrow, bool releaseToSeller) external inState(State.DISPUTED) {
        require(msg.sender == arbiter, "only arbiter hook");
        require(escrow == address(this), "wrong escrow");
        _resolve(releaseToSeller);
        emit DisputeResolved(msg.sender, releaseToSeller);
    }

    // ---- Mutual / buyer-only cancellation paths --------------------------

    /**
     * Buyer can cancel ONLY if no milestone marked delivered yet.
     * Refunds everything (minus nothing, fee not charged).
     */
    function cancelNoDelivery() external onlyBuyer inState(State.ACTIVE) {
        require(sellerMarkedAt[currentMilestone] == 0, "already marked");
        _refundAllToBuyer();
        state = State.CANCELLED;
        emit Cancelled(msg.sender, totalAmount);
        _returnCollateralIfAny();
    }

    /**
     * Mutual cancel at any time: requires both sides to signal in same tx via parameters.
     * For simple demo: seller calls, buyer must have set an approval flag off-chain logic not included.
     * (In real app you’d make a two-step commit or EIP-712 signed cancel.)
     */
    function cancelMutual() external inState(State.ACTIVE) {
        require(msg.sender == buyer || msg.sender == seller, "no auth");
        // Refund remaining (unpaid) amount to buyer.
        uint256 remaining = _remainingAmount();
        _payTo(buyer, remaining);
        state = State.CANCELLED;
        emit Cancelled(msg.sender, remaining);
        _returnCollateralIfAny();
    }

    // ---- Ratings (off-chain UX) ------------------------------------------

    function emitRatings(uint8 buyerRating, uint8 sellerRating, string calldata meta) external {
        // anyone can emit; frontends can filter by address
        require(buyerRating <= 10 && sellerRating <= 10, "0..10");
        emit Rated(msg.sender, buyerRating, sellerRating, meta);
    }

    // ---- Internal core ----------------------------------------------------

    function _resolve(bool releaseToSeller) internal {
        // Pay out entire remaining amount either way, close escrow.
        uint256 remaining = _remainingAmount();

        if (remaining > 0) {
            if (releaseToSeller) {
                // platform fee on remaining
                (uint256 netToSeller, uint256 fee) = _takeFee(remaining);
                _payTo(seller, netToSeller);
                if (fee > 0 && feeRecipient != address(0)) _payTo(feeRecipient, fee);
            } else {
                _payTo(buyer, remaining);
            }
        }

        state = State.COMPLETE;
        _returnCollateralIfAny();
    }

    function _releaseCurrentMilestone(bool autoTriggered) internal {
        require(state == State.ACTIVE, "bad state");
        uint256 idx = currentMilestone;
        require(idx < milestoneBps.length, "done");
        require(sellerMarkedAt[idx] != 0, "not marked");

        uint256 amt = currentMilestoneAmount();

        // Compute penalty if after deadline
        uint256 penalty;
        if (block.timestamp > milestoneDeadlines[idx] && dailyPenaltyBps > 0) {
            uint256 daysLate = (block.timestamp - milestoneDeadlines[idx]) / 1 days;
            uint256 penaltyBps = dailyPenaltyBps * daysLate;
            if (penaltyBps > maxPenaltyBps) penaltyBps = maxPenaltyBps;
            penalty = (amt * penaltyBps) / 10000;
        }

        // Platform fee on the (amount - penalty)
        uint256 base = amt - penalty;
        (uint256 netToSeller, uint256 fee) = _takeFee(base);

        // Transfer penalty to buyer, fee to platform, net to seller
        if (penalty > 0) _payTo(buyer, penalty);
        if (fee > 0 && feeRecipient != address(0)) _payTo(feeRecipient, fee);
        _payTo(seller, netToSeller);

        emit Approved(idx, netToSeller, fee, penalty);

        // Move to next milestone or complete
        currentMilestone += 1;
        if (currentMilestone >= milestoneBps.length) {
            state = State.COMPLETE;
            _returnCollateralIfAny();
        }
    }

    function _remainingAmount() internal view returns (uint256) {
        if (currentMilestone >= milestoneBps.length) return 0;
        uint256 remainingBps;
        for (uint256 i = currentMilestone; i < milestoneBps.length; i++) {
            remainingBps += milestoneBps[i];
        }
        return (totalAmount * remainingBps) / 10000;
    }

    function _takeFee(uint256 amt) internal view returns (uint256 net, uint256 fee) {
        if (feeBps == 0) return (amt, 0);
        fee = (amt * feeBps) / 10000;
        net = amt - fee;
    }

    function _returnCollateralIfAny() internal {
        if (collateralNft != address(0)) {
            // In this template, collateral always returns to buyer once escrow ends
            IERC721(collateralNft).transferFrom(address(this), buyer, collateralTokenId);
            emit CollateralReturned(collateralNft, collateralTokenId);
        }
    }

    function _refundAllToBuyer() internal {
        _payTo(buyer, totalAmount);
    }

    function _payTo(address to, uint256 amt) internal {
        if (amt == 0) return;
        if (paymentToken == address(0)) {
            (bool ok, ) = to.call{value: amt}("");
            require(ok, "eth xfer fail");
        } else {
            require(IERC20(paymentToken).transfer(to, amt), "erc20 xfer fail");
        }
    }

    // ---- Fallbacks --------------------------------------------------------

    receive() external payable {
        // only accept ETH in exact deposit flow; otherwise block random sends
        require(paymentToken == address(0) && state == State.AWAITING_DEPOSIT, "no direct ETH");
    }
}
