// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleERC20{
    string public name = "Simpletoken";
    string public symbol = "PRIS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address =>uint256) public balanceOf;
    mapping(address =>mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     constructor (uint256 _initialSupply) {
        totalSupply = _initialSupply ** (uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        feeWallet = msg.sender;
     }

     function transfer(address _to, uint256 _value) public returns (bool) {
     require(balanceOf[msg.sender] >= _value, "not enough balance");
     _transfer(msg.sender, _to, _value);
     return true;
     }

     function approve(address _spender, uint256 _value) public 
     returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
     }
     
     function transferFrom(address _from, address _to, uint256 _value)
      public returns(bool) {
        require (balanceOf[msg.sender] >= _value,
        "not enough balance");
        require(allowance[_from][msg.sender] >= _value,
         "allowance to low");
         _transfer(_from, _to, _value);
         return true;
      }

         function _transfer (address _from, address _to, 
         uint256 _value) internal {
            require(_to != address(0), "invalid address");
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
         }

         function burn(uint256 amount) public {
            require (balanceOf[msg.sender] >= amount,
            "not enough tokens");
            balanceOf[msg.sender] -= amount;
            totalSupply -= amount;
         }

         function mint(address _to, uint256 _amount)public  {
            totalSupply += _amount;
            balanceOf[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
         }

         uint256 public feePercent = 2;
         address public feeWallet;
         uint256 public burnPercent = 1;

         function _tranferWithFees (address from, address to,
          uint256 _amount) internal {
            require (balanceOf[msg.sender] >= _amount, 
            "not enough balance");
            uint256 fee = (_amount * feePercent)/100;
            uint256 amountAfterFee = _amount - fee;

            balanceOf[from] -= _amount;
            balanceOf[feeWallet] += fee;
            balanceOf[to] += amountAfterFee;
        
          }

          function burn (address from, address to, uint256 _amount) internal{
            require (balanceOf[msg.sender] >= _amount,
             "insufficient balance");

            uint256 burnAmount = (_amount * burnPercent)/100;
            uint256 amountAfterBurn = _amount - burnAmount;

            balanceOf[from] -= _amount;

            balanceOf[to] += amountAfterBurn;
            totalSupply -= burnAmount;
            
          }


        
      }





    
