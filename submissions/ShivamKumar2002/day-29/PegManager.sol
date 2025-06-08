// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";

/**
 * @title PegManager
 * @author shivam
 * @notice Manages the peg of the LDOLLAR stablecoin to USD by allowing users to deposit ETH to mint LDOLLAR and redeem LDOLLAR for ETH.
 * @dev - Uses an external ETH/USD price feed (simulated here by `ethUsdPrice`).
 *      - Requires the associated StableCoin contract to have this contract set as its PegManager.
 */
contract PegManager {
    /// @notice The address of the contract owner.
    address public owner;

    /// @notice The address of the associated StableCoin contract.
    StableCoin public stableCoin;

    /// @notice The current price of 1 ETH in USD, scaled by 10**18.
    uint256 public ethUsdPrice;

    /// @notice Emitted when a user deposits ETH and mints LDOLLAR.
    /// @param user The address of the user who deposited.
    /// @param ethAmount The amount of ETH deposited (in wei).
    /// @param ldollarMinted The amount of LDOLLAR tokens minted (in wei).
    event EthDeposited(
        address indexed user,
        uint256 ethAmount,
        uint256 ldollarMinted
    );

    /// @notice Emitted when a user redeems LDOLLAR for ETH.
    /// @param user The address of the user who redeemed.
    /// @param ldollarAmount The amount of LDOLLAR tokens redeemed (in wei).
    /// @param ethReturned The amount of ETH returned (in wei).
    event LdollarRedeemed(
        address indexed user,
        uint256 ldollarAmount,
        uint256 ethReturned
    );

    /// @notice Emitted when the ETH/USD price is updated.
    /// @param oldPrice The previous ETH/USD price.
    /// @param newPrice The new ETH/USD price.
    event EthPriceUpdated(uint256 oldPrice, uint256 newPrice);

    /**
     * @dev Modifier to restrict function calls to the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "PegManager: Caller is not the owner");
        _;
    }

    /**
     * @param _stableCoinAddress The address of the deployed StableCoin contract.
     * @param _initialEthUsdPrice The initial price of 1 ETH in USD, scaled by 10**18. e.g., if 1 ETH = $3000, _initialEthUsdPrice should be 3000 * 10**18.
     */
    constructor(address _stableCoinAddress, uint256 _initialEthUsdPrice) {
        require(
            _stableCoinAddress != address(0),
            "PegManager: Invalid StableCoin address"
        );
        require(
            _initialEthUsdPrice > 0,
            "PegManager: Initial price must be positive"
        );
        owner = msg.sender;
        stableCoin = StableCoin(_stableCoinAddress);
        ethUsdPrice = _initialEthUsdPrice;

        // Important: The owner of PegManager must also call setPegManager()
        // on the StableCoin contract, passing this PegManager's address.
    }

    /**
     * @notice Allows the owner to update the ETH/USD price.
     * @param _newPrice The new price of 1 ETH in USD, scaled by 10**18.
     */
    function updateEthPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "PegManager: Price must be positive");
        uint256 oldPrice = ethUsdPrice;
        ethUsdPrice = _newPrice;
        emit EthPriceUpdated(oldPrice, _newPrice);
    }

    /// @notice Deposits ETH and mints LDOLLAR tokens for the sender.
    function deposit() external payable {
        require(msg.value > 0, "PegManager: Deposit amount must be positive");
        require(ethUsdPrice > 0, "PegManager: ETH price not set or invalid");

        // Calculate LDOLLAR to mint.
        // msg.value is in wei (10**18 per ETH)
        // ethUsdPrice is scaled by 10**18
        // ldollar has 18 decimals
        // amountLdollar = (msg.value * ethUsdPrice) / (1 ether)
        // amountLdollar = (msg.value * ethUsdPrice) / 10**18
        uint256 amountLdollar = (msg.value * ethUsdPrice) / (1 ether); // 1 ether == 10**18
        require(
            amountLdollar > 0,
            "PegManager: Calculated LDOLLAR amount is zero"
        );

        // Mint new StableCoins to the depositor
        stableCoin.mint(msg.sender, amountLdollar);

        emit EthDeposited(msg.sender, msg.value, amountLdollar);
    }

    /**
     * @notice Redeems LDOLLAR tokens for ETH.
     * @dev Calculates the amount of ETH to return based on the LDOLLAR amount and the current ETH/USD price.
     * @param _amountLdollar The amount of LDOLLAR tokens to redeem (in wei, 10**18 scale).
     */
    function redeem(uint256 _amountLdollar) external {
        require(
            _amountLdollar > 0,
            "PegManager: Redeem amount must be positive"
        );
        require(ethUsdPrice > 0, "PegManager: ETH price not set or invalid");
        require(
            stableCoin.balanceOf(msg.sender) >= _amountLdollar,
            "PegManager: Insufficient LDOLLAR balance"
        );

        // Calculate ETH to return
        // amountEth = (_amountLdollar * 1 ether) / ethUsdPrice
        uint256 amountEth = (_amountLdollar * (1 ether)) / ethUsdPrice;
        require(amountEth > 0, "PegManager: Calculated ETH amount is zero");
        require(
            address(this).balance >= amountEth,
            "PegManager: Insufficient ETH reserves in contract"
        );

        // Burn the user's StableCoins
        // Note: StableCoin.burn requires PegManager to be the caller,
        // and allows burning from any address ('from').
        stableCoin.burn(msg.sender, _amountLdollar);

        // Send ETH back to the user
        (bool success, ) = msg.sender.call{value: amountEth}("");
        require(success, "PegManager: ETH transfer failed");

        emit LdollarRedeemed(msg.sender, _amountLdollar, amountEth);
    }
}
