// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Statistics {

    function mean(uint256[] memory numbers) public pure returns (uint256) {
        require(numbers.length > 0, "Array empty");

        uint256 sum = 0;

        for(uint256 i = 0; i < numbers.length; i++){
            sum += numbers[i];
        }

        return sum / numbers.length;
    }

    function range(uint256[] memory numbers) public pure returns(uint256){
        require(numbers.length > 0, "Array empty");

        uint256 min = numbers[0];
        uint256 max = numbers[0];

        for(uint256 i = 1; i < numbers.length; i++){

            if(numbers[i] < min){
                min = numbers[i];
            }

            if(numbers[i] > max){
                max = numbers[i];
            }
        }

        return max - min;
    }

    function mode(uint256[] memory numbers) public pure returns(uint256){

        uint256 modeValue = numbers[0];
        uint256 maxCount = 0;

        for(uint256 i = 0; i < numbers.length; i++){

            uint256 count = 0;

            for(uint256 j = 0; j < numbers.length; j++){
                if(numbers[j] == numbers[i]){
                    count++;
                }
            }

            if(count > maxCount){
                maxCount = count;
                modeValue = numbers[i];
            }
        }

        return modeValue;
    }

    function variance(uint256[] memory numbers) public pure returns(uint256){

        uint256 avg = mean(numbers);
        uint256 sum = 0;

        for(uint256 i = 0; i < numbers.length; i++){

            uint256 diff;

            if(numbers[i] > avg){
                diff = numbers[i] - avg;
            } else {
                diff = avg - numbers[i];
            }

            sum += diff * diff;
        }

        return sum / numbers.length;
    }
}