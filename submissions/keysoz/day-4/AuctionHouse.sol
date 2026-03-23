// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error AuctionHouse__EditBannedAfterConfirmation(uint256 index);
error AuctionHouse__DeleteBannedAfterBidPlace(uint256 index);
error AuctionHouse__AuctionEnded(uint256 index, uint256 endedTime);
error AuctionHouse__BidLowerThanCurrentPrice(uint256 index, uint256 value, uint256 current);
error AuctionHouse__OwnerPreventedFromBanPlace(uint256 index, address owner);
error AuctionHouse__HaveNoBidPlace(uint256 index, address caller);
error AuctionHouse__AlreadyConfirmed(uint256 index);
error AuctionHouse__UnAuthorized(address caller);
error AuctionHouse__NonExistedItem(uint256 index);
error AuctionHouse__InvalidDuration(uint256 duration);
error AuctionHouse__AuctionStillActive(uint256 index);
error AuctionHouse__WinnerCannotRefund(uint256 index, address caller);
error AuctionHouse__NotActiveItem(uint256 index);
error AuctionHouse__NoBidders(uint256 index);
error AuctionHouse__WithdrawError();

contract AuctionHouse {
    struct Item {
        string name;
        string description;
        string imageUri;
        uint256 startingPrice;
        address owner;
    }

    enum ItemStatus {
        Pending,
        Active,
        Ended,
        Deleted
    }

    Item[] public items;
    uint256 public immutable i_contractFee;
    address private immutable i_owner;
    mapping(uint256 => address) public winner;
    mapping(uint256 => uint256) public endTime;
    mapping(uint256 => uint256) public highestOffer;
    mapping(uint256 => mapping(address => uint256)) public addressToBid;
    mapping(uint256 => ItemStatus) public itemStatus;
    mapping(uint256 => bool) public hasBidders;

    event ItemCreated(uint256 indexed index, address indexed owner, uint256 startingPrice);
    event ItemEdited(uint256 index);
    event ItemConfirmed(uint256 indexed index, uint256 startingTime, uint256 endTime);
    event ItemDeleted(uint256 index);
    event BidPlaced(uint256 indexed index, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed index, address indexed winner, uint256 finalPrice);
    event RefundIssued(uint256 indexed index, address indexed bidder, uint256 amount);

    modifier onlyOwner(uint256 _index) {
        address owner = items[_index].owner;
        if (msg.sender != owner) revert AuctionHouse__UnAuthorized(msg.sender);
        _;
    }

    modifier checkIndex(uint256 _index) {
        if (_index >= items.length) revert AuctionHouse__NonExistedItem(_index);
        _;
    }

    constructor(uint256 _initialFee) {
        require(_initialFee <= 100, "fee must be <= 100");
        i_contractFee = _initialFee;
    }

    receive() external payable {}

    function createItem(
        string calldata _name,
        string calldata _description,
        string calldata _imageURI,
        uint256 _startingPrice
    ) external {
        uint256 currentIndex = items.length;
        address owner = msg.sender;
        items.push(Item(_name, _description, _imageURI, _startingPrice, owner));
        highestOffer[currentIndex] = _startingPrice;
        itemStatus[currentIndex] = ItemStatus.Pending;
        emit ItemCreated(currentIndex, owner, _startingPrice);
    }

    function confirmItem(uint256 _index, uint256 _duration) external checkIndex(_index) onlyOwner(_index) {
        if (itemStatus[_index] == ItemStatus.Deleted) revert AuctionHouse__NonExistedItem(_index);
        if (itemStatus[_index] != ItemStatus.Pending) revert AuctionHouse__AlreadyConfirmed(_index);
        if (_duration < 1 minutes) revert AuctionHouse__InvalidDuration(_duration);
        endTime[_index] = block.timestamp + _duration;
        itemStatus[_index] = ItemStatus.Active;
        emit ItemConfirmed(_index, block.timestamp, endTime[_index]);
    }

    function editItem(
        uint256 _index,
        string calldata _name,
        string calldata _description,
        string calldata _imageURI,
        uint256 _newPrice
    ) external checkIndex(_index) onlyOwner(_index) {
        if (itemStatus[_index] == ItemStatus.Deleted) revert AuctionHouse__NonExistedItem(_index);
        if (itemStatus[_index] != ItemStatus.Pending) revert AuctionHouse__EditBannedAfterConfirmation(_index);
        items[_index] = Item(_name, _description, _imageURI, _newPrice, items[_index].owner);
        highestOffer[_index] = _newPrice;
        emit ItemEdited(_index);
    }

    function deleteItem(uint256 _index) external checkIndex(_index) onlyOwner(_index) {
        if (itemStatus[_index] == ItemStatus.Deleted) revert AuctionHouse__NonExistedItem(_index);
        if (itemStatus[_index] == ItemStatus.Ended) revert AuctionHouse__AuctionEnded(_index, endTime[_index]);
        if (itemStatus[_index] == ItemStatus.Active && hasBidders[_index]) {
            revert AuctionHouse__DeleteBannedAfterBidPlace(_index);
        }
        itemStatus[_index] = ItemStatus.Deleted;
        emit ItemDeleted(_index);
    }

    function placeBid(uint256 _index) external payable checkIndex(_index) {
        if (itemStatus[_index] != ItemStatus.Active) revert AuctionHouse__NotActiveItem(_index);
        if (block.timestamp >= endTime[_index]) revert AuctionHouse__AuctionEnded(_index, endTime[_index]);
        if (msg.sender == items[_index].owner) revert AuctionHouse__OwnerPreventedFromBanPlace(_index, msg.sender);
        uint256 totalBid = addressToBid[_index][msg.sender] + msg.value;
        if (totalBid <= highestOffer[_index]) {
            revert AuctionHouse__BidLowerThanCurrentPrice(_index, msg.value, highestOffer[_index]);
        }
        addressToBid[_index][msg.sender] += msg.value;
        highestOffer[_index] = addressToBid[_index][msg.sender];
        hasBidders[_index] = true;
        winner[_index] = msg.sender;
        emit BidPlaced(_index, msg.sender, msg.value);
    }

    function claimRefund(uint256 _index) external checkIndex(_index) {
        if (itemStatus[_index] == ItemStatus.Pending) revert AuctionHouse__NotActiveItem(_index);
        if (itemStatus[_index] == ItemStatus.Active && block.timestamp < endTime[_index]) {
            revert AuctionHouse__AuctionStillActive(_index);
        }
        if (addressToBid[_index][msg.sender] == 0) revert AuctionHouse__HaveNoBidPlace(_index, msg.sender);
        if (msg.sender == winner[_index]) {
            revert AuctionHouse__WinnerCannotRefund(_index, msg.sender);
        }
        uint256 refundAmount = addressToBid[_index][msg.sender];
        addressToBid[_index][msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) revert AuctionHouse__WithdrawError();
        emit RefundIssued(_index, msg.sender, refundAmount);
    }

    function endAuction(uint256 _index) external checkIndex(_index) {
        if (itemStatus[_index] == ItemStatus.Ended) {
            revert AuctionHouse__AuctionEnded(_index, endTime[_index]);
        }
        if (itemStatus[_index] == ItemStatus.Deleted) revert AuctionHouse__NonExistedItem(_index);
        if (itemStatus[_index] == ItemStatus.Pending) revert AuctionHouse__NotActiveItem(_index);
        if (block.timestamp < endTime[_index]) revert AuctionHouse__AuctionStillActive(_index);
        if (!hasBidders[_index]) revert AuctionHouse__NoBidders(_index);
        itemStatus[_index] = ItemStatus.Ended;
        address auctionOwner = items[_index].owner;
        uint256 fee = (highestOffer[_index] * i_contractFee) / 100;
        uint256 amount = highestOffer[_index] - fee;
        items[_index].owner = winner[_index];
        emit AuctionEnded(_index, winner[_index], highestOffer[_index]);
        addressToBid[_index][auctionOwner] += amount;
    }

    function WithdrawContractFees() external {
        if (msg.sender != i_owner) revert AuctionHouse__UnAuthorized(msg.sender);
        revert("Unsafe: contract balance includes escrowed bidder funds");
    } //withdraw Fee
}
