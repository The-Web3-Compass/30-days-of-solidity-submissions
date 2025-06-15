
constructor(
    uint256 _initialSupply,
    uint256 _tokenPrice,
    uint256 _saleDurationInSeconds,
    uint256 _minPurchase,
    uint256 _maxPurchase,
    address _projectOwner
) SimpleERC20(_initialSupply) {
    tokenPrice = _tokenPrice;
    saleStartTime = block.timestamp;
    saleEndTime = block.timestamp + _saleDurationInSeconds;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    projectOwner = _projectOwner;

    // Transfer all tokens to this contract for sale
    _transfer(msg.sender, address(this), totalSupply);

    // Mark that we've moved tokens from the deployer
    initialTransferDone = true;
}

