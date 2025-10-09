//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Interface for the CalculatorController
interface ICalculatorController {
	function add(uint256 a, uint256 b) external pure returns (uint256);
	function sub(uint256 a, uint256 b) external pure returns (uint256);
	function mul(uint256 a, uint256 b) external pure returns (uint256);
	function div(uint256 a, uint256 b) external pure returns (uint256);
}

// SmartCalculator delegates calculations to CalculatorController
contract SmartCalculator {
	address public controller;

	constructor(address _controller) {
		controller = _controller;
	}

	function add(uint256 a, uint256 b) external view returns (uint256) {
		return ICalculatorController(controller).add(a, b);
	}

	function sub(uint256 a, uint256 b) external view returns (uint256) {
		return ICalculatorController(controller).sub(a, b);
	}

	function mul(uint256 a, uint256 b) external view returns (uint256) {
		return ICalculatorController(controller).mul(a, b);
	}

	function div(uint256 a, uint256 b) external view returns (uint256) {
		return ICalculatorController(controller).div(a, b);
	}
}