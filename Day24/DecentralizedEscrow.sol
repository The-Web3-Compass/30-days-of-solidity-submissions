// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedEscrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    enum State { AWAITING_FUND, FUNDED, RELEASED, REFUNDED, DISPUTED, RESOLVED }

    struct Escrow {
        address payer;
        address payee;
        address arbitrator;
        address token;
        uint256 amount;
        uint256 deadline;
        bytes32 conditionHash;
        State state;
        uint256 createdAt;
        uint256 fundedAt;
        string meta;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => mapping(address => uint256)) public balances;

    uint256 public feeBps;
    address public feeCollector;

    event EscrowCreated(uint256 indexed escrowId, address indexed payer, address indexed payee, address token, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId, address indexed funder, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId, address indexed by);
    event EscrowRefunded(uint256 indexed escrowId, address indexed by);
    event EscrowDisputed(uint256 indexed escrowId, address indexed by);
    event EscrowResolved(uint256 indexed escrowId, address indexed resolver, bool releasedToPayee);
    event Withdrawn(address indexed account, address indexed token, uint256 amount);
    event FeeSettingsUpdated(uint256 newFeeBps, address newCollector);

    modifier onlyParticipant(uint256 escrowId) {
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.payer || msg.sender == e.payee || msg.sender == e.arbitrator, "not a participant");
        _;
    }

    modifier inState(uint256 escrowId, State s) {
        require(escrows[escrowId].state == s, "invalid state");
        _;
    }

    constructor(uint256 _feeBps, address _feeCollector) {
        require(_feeBps <= 10000, "bps>10000");
        feeBps = _feeBps;
        feeCollector = _feeCollector == address(0) ? owner() : _feeCollector;
        nextEscrowId = 1;
    }

    function createEscrow(
        address payee,
        address arbitrator,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes32 conditionHash,
        string calldata meta
    ) external returns (uint256) {
        require(payee != address(0), "invalid payee");
        require(amount > 0, "amount>0");
        uint256 id = nextEscrowId++;
        escrows[id] = Escrow({
            payer: msg.sender,
            payee: payee,
            arbitrator: arbitrator,
            token: token,
            amount: amount,
            deadline: deadline,
            conditionHash: conditionHash,
            state: State.AWAITING_FUND,
            createdAt: block.timestamp,
            fundedAt: 0,
            meta: meta
        });
        emit EscrowCreated(id, msg.sender, payee, token, amount);
        return id;
    }

    function fundEscrow(uint256 escrowId) external payable nonReentrant inState(escrowId, State.AWAITING_FUND) {
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.payer, "only payer funds");
        if (e.token == address(0)) {
            require(msg.value == e.amount, "incorrect ETH amount");
        } else {
            require(msg.value == 0, "no ETH for ERC20");
            IERC20(e.token).safeTransferFrom(msg.sender, address(this), e.amount);
        }
        e.state = State.FUNDED;
        e.fundedAt = block.timestamp;
        emit EscrowFunded(escrowId, msg.sender, e.amount);
    }

    function releaseToPayee(uint256 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(e.state == State.FUNDED || e.state == State.DISPUTED, "not fundable or disputable");
        require(msg.sender == e.payer || msg.sender == e.arbitrator || msg.sender == e.payee, "unauthorized");
        if (e.state == State.DISPUTED) require(msg.sender == e.arbitrator, "only arbitrator");
        e.state = State.RELEASED;
        _disburse(escrowId, true);
        emit EscrowReleased(escrowId, msg.sender);
    }

    function refundToPayer(uint256 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(e.state == State.FUNDED || e.state == State.DISPUTED, "not fundable or disputable");
        require(msg.sender == e.payer || msg.sender == e.arbitrator || msg.sender == e.payee, "unauthorized");
        if (e.state == State.DISPUTED) require(msg.sender == e.arbitrator, "only arbitrator");
        else require(msg.sender == e.payer || msg.sender == e.arbitrator, "only payer/arbitrator");
        e.state = State.REFUNDED;
        _disburse(escrowId, false);
        emit EscrowRefunded(escrowId, msg.sender);
    }

    function openDispute(uint256 escrowId, string calldata) external {
        Escrow storage e = escrows[escrowId];
        require(e.state == State.FUNDED, "not funded");
        require(msg.sender == e.payer || msg.sender == e.payee, "only payer or payee");
        e.state = State.DISPUTED;
        emit EscrowDisputed(escrowId, msg.sender);
    }

    function resolveDispute(uint256 escrowId, bool releaseToPayee) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(e.state == State.DISPUTED, "not disputed");
        require(msg.sender == e.arbitrator, "only arbitrator");
        e.state = State.RESOLVED;
        _disburse(escrowId, releaseToPayee);
        emit EscrowResolved(escrowId, msg.sender, releaseToPayee);
    }

    function _disburse(uint256 escrowId, bool toPayee) internal {
        Escrow storage e = escrows[escrowId];
        require(e.state == State.RELEASED || e.state == State.REFUNDED || e.state == State.RESOLVED, "invalid state");
        uint256 gross = e.amount;
        uint256 fee = (feeBps == 0 || feeCollector == address(0)) ? 0 : (gross * feeBps) / 10000;
        uint256 net = gross - fee;
        address recipient = toPayee ? e.payee : e.payer;
        address tokenAddr = e.token;
        if (fee > 0) balances[feeCollector][tokenAddr] += fee;
        balances[recipient][tokenAddr] += net;
        e.amount = 0;
    }

    function withdraw(address token) external nonReentrant {
        uint256 amt = balances[msg.sender][token];
        require(amt > 0, "no balance");
        balances[msg.sender][token] = 0;
        if (token == address(0)) {
            (bool sent, ) = msg.sender.call{value: amt}("");
            require(sent, "ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(msg.sender, amt);
        }
        emit Withdrawn(msg.sender, token, amt);
    }

    function setFee(uint256 _feeBps, address _feeCollector) external onlyOwner {
        require(_feeBps <= 10000, "bps>10000");
        feeBps = _feeBps;
        feeCollector = _feeCollector == address(0) ? owner() : _feeCollector;
        emit FeeSettingsUpdated(_feeBps, feeCollector);
    }

    function getEscrow(uint256 id) external view returns (Escrow memory) {
        return escrows[id];
    }

    receive() external payable {
        revert("Use fundEscrow");
    }

    fallback() external payable {
        revert("Use fundEscrow");
    }
}
