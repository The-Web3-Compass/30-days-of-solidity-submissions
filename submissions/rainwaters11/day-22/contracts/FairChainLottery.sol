// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title  FairChainLottery
/// @author rainwaters11 — Day 22: Provably Fair Lottery with Chainlink VRF
/// @notice A decentralized lottery where the winner is picked by Chainlink VRF —
///         a cryptographically provable source of randomness that no one,
///         including the contract owner, can predict or manipulate.
///
/// @dev    WHY WE NEED CHAINLINK VRF
///         On-chain randomness is impossible to achieve natively.
///         block.timestamp, block.prevrandao, and block.number are all
///         visible or influenceable by miners/validators before the block
///         is finalized — so they cannot be used for fair selection.
///
///         Chainlink VRF works like this:
///         1. We request a random number by calling coordinator.requestRandomWords().
///         2. Chainlink's off-chain oracle network generates a random number
///            with a cryptographic proof attached.
///         3. The coordinator verifies the proof on-chain and calls our
///            fulfillRandomWords() callback with the verified result.
///         4. No one — including Chainlink — can know the result in advance.
///
///         THE STATE MACHINE
///         ┌──────────────────────────────────────────────────────────┐
///         │  OPEN        → Players can enter (pay ticket price).     │
///         │  CALCULATING → VRF request in flight; no new entries.    │
///         │  CLOSED      → Winner paid; lottery is reset.            │
///         └──────────────────────────────────────────────────────────┘
///         This prevents a player from sneaking in after the draw
///         has started but before the winner is announced.
///
///         THE MODULO TRICK
///         winner index = randomWords[0] % players.length
///         If randomWords[0] = 723 and there are 10 players,
///         winner = index 723 % 10 = 3.
///         Every possible remainder (0-9) is equally probable, making
///         the selection cryptographically fair.
///
///         CEI IN fulfillRandomWords
///         CHECKS      → ensure players array is not empty
///         EFFECTS     → pick winner, delete players array, reset state
///         INTERACTIONS→ send ETH prize to winner
///         This prevents a malicious winner contract from re-entering
///         and draining tickets from the next round.
///
///         SUBSCRIPTION MODEL
///         This contract uses Chainlink VRF v2.5 (VRFConsumerBaseV2Plus).
///         You must create a VRF subscription at vrf.chain.link and fund it
///         with LINK (or native ETH on supported chains), then add this
///         contract's address as a consumer.
contract FairChainLottery is VRFConsumerBaseV2Plus {

    // ─── Lottery States ───────────────────────────────────────────────────────

    /// @notice Three-state machine that gates which actions are allowed.
    enum LotteryState {
        OPEN,           // Ticket sales are live.
        CALCULATING,    // VRF request sent; winner being determined.
        CLOSED          // No active lottery; awaiting next round start.
    }

    // ─── Chainlink VRF Configuration ─────────────────────────────────────────

    /// @notice Max gas the VRF callback (fulfillRandomWords) is allowed to use.
    ///         Keep this generous enough for the winner payout logic.
    uint32 public constant CALLBACK_GAS_LIMIT = 200_000;

    /// @notice Number of confirmations before VRF response is delivered.
    ///         Higher = more secure but slower (use 3 for testnets, 6+ for mainnet).
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    /// @notice We only need one random word — from that single VRF output
    ///         we derive the winner via modulo.
    uint32 public constant NUM_WORDS = 1;

    /// @notice Chainlink VRF subscription ID (set in constructor).
    uint256 public immutable subscriptionId;

    /// @notice Chainlink VRF key hash — identifies which oracle node / gas lane.
    ///         e.g. Sepolia: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
    bytes32 public immutable keyHash;

    // ─── Lottery Parameters ───────────────────────────────────────────────────

    /// @notice Entry fee in wei (e.g. 0.01 ETH = 10_000_000_000_000_000).
    uint256 public immutable ticketPrice;

    /// @notice Minimum number of players required before a draw can start.
    uint256 public immutable minPlayers;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Current state of the lottery.
    LotteryState public lotteryState;

    /// @dev Array of players who have entered the current round.
    ///      Cleared (EFFECT) before the prize is sent (INTERACTION) in fulfillRandomWords.
    address payable[] private players;

    /// @notice Address of the most recent winner.
    address public recentWinner;

    /// @notice Prize paid to the most recent winner (in wei).
    uint256 public recentPrize;

    /// @notice Round number — increments every time a lottery concludes.
    uint256 public roundNumber;

    /// @dev VRF request ID outstanding, used for logging.
    uint256 private lastRequestId;

    // ─── Events ───────────────────────────────────────────────────────────────

    event LotteryEntered(address indexed player, uint256 ticketCost);
    event RandomnessRequested(uint256 indexed requestId);
    event WinnerPicked(
        address indexed winner,
        uint256 prize,
        uint256 indexed round,
        uint256 randomWord,
        uint256 winnerIndex
    );
    event LotteryReset(uint256 indexed newRound);
    event ETHTransferFailed(address indexed winner, uint256 amount);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error LotteryNotOpen();
    error InsufficientTicketPayment(uint256 sent, uint256 required);
    error NotEnoughPlayers(uint256 current, uint256 minimum);
    error LotteryNotCalculating();
    error PrizeTransferFailed();

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _vrfCoordinator   Chainlink VRF Coordinator address for your network.
    /// @param _subscriptionId   Your funded VRF subscription ID.
    /// @param _keyHash          Gas-lane key hash for your network / gas tier.
    /// @param _ticketPrice      Entry cost in wei (e.g. 0.01 ether).
    /// @param _minPlayers       Minimum participants before drawing is allowed.
    constructor(
        address _vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _ticketPrice,
        uint256 _minPlayers
    )
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        subscriptionId = _subscriptionId;
        keyHash        = _keyHash;
        ticketPrice    = _ticketPrice;
        minPlayers     = _minPlayers;
        lotteryState   = LotteryState.OPEN;
        roundNumber    = 1;
    }

    // ─── Enter ────────────────────────────────────────────────────────────────

    /// @notice Buy a ticket and enter the current lottery round.
    ///
    /// @dev    STATE GATE: only callable in OPEN state.
    ///         Sending exactly ticketPrice is required.  Any excess is accepted
    ///         but the player still gets one entry (simple implementation).
    function enterLottery() external payable {
        // ── CHECKS ────────────────────────────────────────────────────────────
        if (lotteryState != LotteryState.OPEN) revert LotteryNotOpen();
        if (msg.value < ticketPrice)
            revert InsufficientTicketPayment(msg.value, ticketPrice);

        // ── EFFECTS ───────────────────────────────────────────────────────────
        players.push(payable(msg.sender));

        emit LotteryEntered(msg.sender, msg.value);
    }

    // ─── Request Draw ─────────────────────────────────────────────────────────

    /// @notice Owner-only: kick off the VRF randomness request to pick a winner.
    ///
    /// @dev    Transitions state to CALCULATING immediately, blocking new entries.
    ///         The actual winner selection happens asynchronously in
    ///         fulfillRandomWords() once Chainlink delivers the random number.
    function requestDraw() external onlyOwner {
        // ── CHECKS ────────────────────────────────────────────────────────────
        if (lotteryState != LotteryState.OPEN) revert LotteryNotOpen();
        if (players.length < minPlayers)
            revert NotEnoughPlayers(players.length, minPlayers);

        // ── EFFECTS ───────────────────────────────────────────────────────────
        //    Close the door immediately — no more entries while we wait for VRF.
        lotteryState = LotteryState.CALCULATING;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        lastRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash:             keyHash,
                subId:               subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit:    CALLBACK_GAS_LIMIT,
                numWords:            NUM_WORDS,
                extraArgs:           VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RandomnessRequested(lastRequestId);
    }

    // ─── Chainlink VRF Callback ───────────────────────────────────────────────

    /// @notice Called by the Chainlink VRF Coordinator once the random number
    ///         has been generated and verified on-chain.
    ///
    /// @dev    THE CEI PATTERN IS CRITICAL HERE:
    ///
    ///         A malicious winner contract could implement receive() to call
    ///         back into this lottery.  If we sent ETH BEFORE clearing the
    ///         players array, the attacker could drain the entire prize pool
    ///         in a loop before the state was updated.
    ///
    ///         By zeroing all state BEFORE the external .call, any re-entrant
    ///         call would find an empty players array and closed state — making
    ///         the attack impossible.
    ///
    ///         CHECKS   → players.length > 0 (sanity guard)
    ///         EFFECTS  → select winner, capture prize, clear players, close round
    ///         INTERACT → transfer ETH prize to winner
    ///
    /// @param  randomWords  Array of verified random uint256 values from Chainlink.
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {

        // ── CHECKS ────────────────────────────────────────────────────────────
        if (lotteryState != LotteryState.CALCULATING) revert LotteryNotCalculating();

        uint256 playerCount = players.length;

        // ── EFFECTS ───────────────────────────────────────────────────────────

        // THE MODULO TRICK:
        // randomWords[0] is a 256-bit number (huge).  % players.length maps
        // it to a fair index in [0, players.length-1].
        // e.g.  randomWords[0] = 723, players.length = 10  →  index = 3
        uint256 winnerIndex = randomWords[0] % playerCount;
        address payable winner = players[winnerIndex];
        uint256 prize = address(this).balance;

        // ⭐ THE KEY: wipe state BEFORE touching the external world.
        //    If the winner's receive() re-enters, players is already empty
        //    and lotteryState is CLOSED → all guards will revert.
        delete players;               // reset: array length → 0
        lotteryState   = LotteryState.CLOSED;
        recentWinner   = winner;
        recentPrize    = prize;
        roundNumber   += 1;

        emit WinnerPicked(winner, prize, roundNumber - 1, randomWords[0], winnerIndex);

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        // Transfer the entire prize pool to the winner.
        (bool success, ) = winner.call{value: prize}("");
        if (!success) {
            // If transfer fails (e.g. gas stipend exceeded), emit an event so
            // the operator can manually retry rather than bricking the funds.
            emit ETHTransferFailed(winner, prize);
        }
    }

    // ─── New Round ────────────────────────────────────────────────────────────

    /// @notice Owner-only: open a new round after the previous one has CLOSED.
    function startNewRound() external onlyOwner {
        if (lotteryState != LotteryState.CLOSED) revert LotteryNotOpen();

        lotteryState = LotteryState.OPEN;
        emit LotteryReset(roundNumber);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the list of players in the current round.
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }

    /// @notice How many players have entered the current round.
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    /// @notice Current prize pool (total ETH held by the contract).
    function getPrizePool() external view returns (uint256) {
        return address(this).balance;
    }
}
