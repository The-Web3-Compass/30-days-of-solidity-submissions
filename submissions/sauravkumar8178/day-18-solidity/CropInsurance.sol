// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    enum PolicyState { Active, Paid, Expired }

    struct Policy {
        address payable farmer;
        uint256 premium;      // in wei
        uint256 payout;       // in wei
        uint256 latE6;        // latitude * 1e6
        uint256 lonE6;        // longitude * 1e6
        uint256 startTs;      // unix start
        uint256 endTs;        // unix end
        uint256 rainfallThresholdMM; // mm threshold
        PolicyState state;
        bytes32 requestId;
    }

    mapping(uint256 => Policy) public policies; // policyId => Policy
    uint256 public nextPolicyId;

    address public linkToken;
    address public oracle;
    bytes32 public jobId;
    uint256 public fee; // LINK fee (in LINK token base units)

    // events
    event PolicyCreated(uint256 policyId, address farmer);
    event RequestSent(uint256 policyId, bytes32 requestId);
    event PolicyPayout(uint256 policyId, address farmer, uint256 amount);
    event PolicyExpired(uint256 policyId);

    // requestId => policyId
    mapping(bytes32 => uint256) public requestToPolicy;

    constructor(address _linkToken, address _oracle, bytes32 _jobId, uint256 _fee) {
        setChainlinkToken(_linkToken);
        linkToken = _linkToken;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    // Owner (insurer) deposits contract balance to pay policies
    receive() external payable {}

    // Create policy: called by insurer/admin
    function createPolicy(
        address payable _farmer,
        uint256 _premium,
        uint256 _payout,
        uint256 _latE6,
        uint256 _lonE6,
        uint256 _startTs,
        uint256 _endTs,
        uint256 _rainfallThresholdMM
    ) external onlyOwner returns (uint256) {
        require(_endTs > _startTs, "invalid period");
        uint256 pid = nextPolicyId++;
        policies[pid] = Policy({
            farmer: _farmer,
            premium: _premium,
            payout: _payout,
            latE6: _latE6,
            lonE6: _lonE6,
            startTs: _startTs,
            endTs: _endTs,
            rainfallThresholdMM: _rainfallThresholdMM,
            state: PolicyState.Active,
            requestId: bytes32(0)
        });
        emit PolicyCreated(pid, _farmer);
        return pid;
    }

    // Anyone (e.g., keeper) triggers evaluation after policy end
    function evaluatePolicy(uint256 policyId) external {
        Policy storage p = policies[policyId];
        require(p.state == PolicyState.Active, "not active");
        require(block.timestamp >= p.endTs, "policy not yet ended");

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // add fields the external adapter expects
        // send lat/lon in decimal with 6 decimals: e.g., 12345678 -> 12.345678
        req.add("lat_e6", toString(p.latE6));
        req.add("lon_e6", toString(p.lonE6));
        req.add("start_ts", toString(p.startTs));
        req.add("end_ts", toString(p.endTs));
        req.add("aggregate", "sum_precip_mm"); // adapter specific

        bytes32 rid = sendChainlinkRequestTo(oracle, req, fee);
        requestToPolicy[rid] = policyId;
        p.requestId = rid;
        emit RequestSent(policyId, rid);
    }

    // Chainlink node calls this to fulfill with aggregated rainfall in mm (integer)
    function fulfill(bytes32 _requestId, uint256 _rainfallMM) public recordChainlinkFulfillment(_requestId) {
        uint256 pid = requestToPolicy[_requestId];
        Policy storage p = policies[pid];
        require(p.state == PolicyState.Active, "policy not active or already resolved");

        if (_rainfallMM < p.rainfallThresholdMM) {
            // pay farmer
            uint256 amount = p.payout;
            require(address(this).balance >= amount, "insufficient contract balance");
            p.state = PolicyState.Paid;
            (bool sent, ) = p.farmer.call{value: amount}("");
            require(sent, "payout failed");
            emit PolicyPayout(pid, p.farmer, amount);
        } else {
            p.state = PolicyState.Expired;
            emit PolicyExpired(pid);
        }
    }

    // Admin can set oracle/job id/fee
    function setOracle(address _oracle) external onlyOwner { oracle = _oracle; }
    function setJobId(bytes32 _jobId) external onlyOwner { jobId = _jobId; }
    function setFee(uint256 _fee) external onlyOwner { fee = _fee; }

    // utility: convert uint256 to string (simple)
    function toString(uint256 value) internal pure returns (string memory) {
        // inspired by OpenZeppelin Strings.toString
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + uint256(temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}
