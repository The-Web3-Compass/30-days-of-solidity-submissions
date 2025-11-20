Day 3 - PollStation (30 Days of Solidity)
PollStation is a simple decentralised voting system built using Solidity and Foundry.

It allows:

Adding candidates
Casting one vote per account
Preventing double voting
Tracking who voted for whom
Viewing total votes
Prerequisites
[Foundry] installed
Node.js (optional, if using frontends later)
Anvil running locally for testing (anvil)
Project Structure
src/PollStation.sol → Main contract
test/PollStation.t.sol → Unit tests using Foundry
script/Deploy.s.sol → Script to deploy contract
script/Vote.s.sol → Script to interact (vote)
foundry.toml → Foundry configuration
Smart Contracts & Scripts
PollStation.sol

Implements a simple voting system.

Add candidates
Vote once per account
Prevent double voting
Track votes and voters
PollStation.t.sol

Unit tests to verify correctness.

Test candidate addition
Test successful voting
Test prevention of double voting
Test invalid candidate voting
Deploy.s.sol

Deployment script.

Deploys PollStation
Adds sample candidates (Alice, Bob)
Vote.s.sol

Interaction script.

Connects to deployed contract
Casts a vote for a candidate
Commands
forge build                # Compile

forge test -vvvv           # Run tests

anvil                      # Start local blockchain

forge script script/Deploy.s.sol:DeployPollStation --rpc-url http://127.0.0.1:8545 --broadcast --private-key <KEY>   # Deploy

forge script script/Vote.s.sol:VoteScript --rpc-url http://127.0.0.1:8545 --broadcast --private-key <KEY>            # Vote

cast call <CONTRACT_ADDRESS> "getCandidateCount()(uint256)" --rpc-url http://127.0.0.1:8545                           # Candidate count

cast call <CONTRACT_ADDRESS> "getVotes(uint256)(uint256)" 0 --rpc-url http://127.0.0.1:8545         
Results
# Test Results
[PASS] testAddCandidate()
[PASS] testCannotDoubleVote()
[PASS] testInvalidCandidateVote()
[PASS] testVote()
Suite result: ok. 4 passed; 0 failed

# Deployment
Contract deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3

# Voting
Same account twice → "Already voted"
Different account → Success
Security Note
Never expose your real private key in scripts or GitHub.

For local testing with Anvil, you can safely use the temporary keys Anvil provides.

For testnets/mainnet, use environment variables (.env file) and reference them in foundry.toml.

Example .env:

PRIVATE_KEY=0xabc123...
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/yourkey
Never commit .env files to GitHub (.gitignore protects them).

End of Project
This project (Day 3 of the 30 Days of Solidity Challenge) demonstrates the complete DApp development cycle with Foundry:

Writing a Solidity smart contract (PollStation.sol)
Testing with Forge (PollStation.t.sol)
Deploying locally using Anvil (Deploy.s.sol)
Interacting via scripts (Vote.s.sol)
Verifying results with cast commands.
