//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
import"./day11.sol";

contract VaultMater is Ownerable{
    event DepositSuccess(address indexed account, uint256 value);
    event WithdrawSuccess(address indexed recipient, uint256 value);

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    function deposit() public payable{
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccess(msg.sender, msg.value);
    }
    function withdraw(address _to, uint256 _amount) public Owner{
        require(_amount >= getBalance(),"don't have much money");
        (bool success,) = payable(_to).call{value:_amount}("");
 
        require(success, "Transfer Failed");

        emit WithdrawSuccess(_to, _amount);

    }

}