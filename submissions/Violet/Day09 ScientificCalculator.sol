// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScientificCalculator {
    uint256 public calculationCount;
    
    event AdvancedCalculation(string operation, uint256 input, uint256 result);
    
    // 幂运算: base^exponent
    function power(uint256 base, uint256 exponent) external returns (uint256) {
        require(base > 0, "Base must be positive");
        require(exponent <= 10, "Exponent too large");
        
        calculationCount++;
        
        if (exponent == 0) return 1;
        
        uint256 result = 1;
        for (uint256 i = 0; i < exponent; i++) {
            result = result * base;
        }
        
        emit AdvancedCalculation("power", base, result);
        return result;
    }
    
    // 平方根 (简化版牛顿法)
    function sqrt(uint256 number) external returns (uint256) {
        calculationCount++;
        
        if (number <= 1) return number;
        
        uint256 x = number;
        uint256 y = (x + 1) / 2;
        
        // 简化迭代次数
        for (uint256 i = 0; i < 5; i++) {
            if (y >= x) break;
            x = y;
            y = (x + number / x) / 2;
        }
        
        emit AdvancedCalculation("sqrt", number, x);
        return x;
    }
    
    // 阶乘
    function factorial(uint256 n) external returns (uint256) {
        require(n <= 10, "Input too large");
        
        calculationCount++;
        
        if (n <= 1) return 1;
        
        uint256 result = 1;
        for (uint256 i = 2; i <= n; i++) {
            result = result * i;
        }
        
        emit AdvancedCalculation("factorial", n, result);
        return result;
    }
    
    // 获取计算次数
    function getCalculationCount() external view returns (uint256) {
        return calculationCount;
    }
}