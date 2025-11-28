// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error InvalidRate();
error SaleClosed();
error InsufficientSupply();
error NothingToWithdraw();

contract PreorderTokens {
    string public name;
    string public symbol;
    uint8 public immutable decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public immutable owner;
    uint256 public rate;            // tokens por 1 ETH
    uint64  public saleStart;
    uint64  public saleEnd;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 ethSpent, uint256 tokensBought);
    event RateUpdated(uint256 newRate);
    event Withdrawn(address indexed to, uint256 amount);
    event UnsoldWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply,
        uint256 _rate,
        uint64 _saleStart,
        uint64 _saleEnd
    ) {
        if (_rate == 0) revert InvalidRate();
        require(_saleStart < _saleEnd, "bad window");

        owner = msg.sender;
        name = _name;
        symbol = _symbol;

        rate = _rate;
        saleStart = _saleStart;
        saleEnd = _saleEnd;

        totalSupply = initialSupply;
        balanceOf[address(this)] = initialSupply;
        emit Transfer(address(0), address(this), initialSupply);
    }

    function buy() external payable {
        if (block.timestamp < saleStart || block.timestamp > saleEnd) revert SaleClosed();
        require(msg.value > 0, "no value");

        uint256 tokens = msg.value * rate;
        if (balanceOf[address(this)] < tokens) revert InsufficientSupply();

        unchecked {
            balanceOf[address(this)] -= tokens;
            balanceOf[msg.sender] += tokens;
        }
        emit Transfer(address(this), msg.sender, tokens);
        emit TokensPurchased(msg.sender, msg.value, tokens);
    }

    function setRate(uint256 newRate) external onlyOwner {
        if (newRate == 0) revert InvalidRate();
        rate = newRate;
        emit RateUpdated(newRate);
    }

    function withdrawETH(address payable to) external onlyOwner {
        uint256 amt = address(this).balance;
        if (amt == 0) revert NothingToWithdraw();
        to.transfer(amt);
        emit Withdrawn(to, amt);
    }

    function withdrawUnsold(address to) external onlyOwner {
        require(block.timestamp > saleEnd, "not ended");
        uint256 amt = balanceOf[address(this)];
        if (amt == 0) revert NothingToWithdraw();
        unchecked {
            balanceOf[address(this)] -= amt;
            balanceOf[to] += amt;
        }
        emit Transfer(address(this), to, amt);
        emit UnsoldWithdrawn(to, amt);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero addr");
        uint256 bal = balanceOf[from];
        require(bal >= amount, "balance");
        unchecked {
            balanceOf[from] = bal - amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}