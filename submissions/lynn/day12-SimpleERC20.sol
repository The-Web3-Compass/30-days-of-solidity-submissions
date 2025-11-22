//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract MySimpleToken is ERC20 {
//     constructor(uint256 _supply) ERC20("MySimpleToken", "MST") {
//         _mint(msg.sender, _supply * (10 ** decimals()));
//     }
// }

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(uint256 _supplyAmount) {
        totalSupply = _supplyAmount * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _amount) public virtual returns(bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool) {
        require(address(0) != _spender, "Invalid address");

        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual returns(bool) {
        require(_amount <= allowance[_from][msg.sender], "Exceed Allowance");
        
        _transfer(_from, _to, _amount);
        allowance[_from][msg.sender] -= _amount;
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(address(0) != _from, "Invalid Address");
        require(_amount <= balanceOf[_from], "Insufficient Balance");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }
}