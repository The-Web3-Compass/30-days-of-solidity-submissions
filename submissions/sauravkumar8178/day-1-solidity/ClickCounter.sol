// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClickCounter {
    uint256 private _count;

    event Clicked(address indexed caller, uint256 newCount);
    event Unclicked(address indexed caller, uint256 newCount);
    event Reset(address indexed caller);

    function getCount() external view returns (uint256) {
        return _count;
    }

    function click() external {
        _count += 1;
        emit Clicked(msg.sender, _count);
    }

    function unclick() external {
        require(_count > 0, "ClickCounter: count already zero");
        _count -= 1;
        emit Unclicked(msg.sender, _count);
    }

    function reset() external {
        _count = 0;
        emit Reset(msg.sender);
    }
}
