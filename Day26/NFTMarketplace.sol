// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

abstract contract ReentrancyGuard {
    uint256 private _status;
    constructor() { _status = 1; }
    modifier nonReentrant() {
        require(_status == 1, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { owner = msg.sender; emit OwnershipTransferred(address(0), msg.sender); }
    modifier onlyOwner() { require(msg.sender == owner, "Ownable: caller is not owner"); _; }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract NFTMarketplace is ReentrancyGuard, Ownable {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) private listings;

    uint256 public platformFeeBps = 250;
    uint256 public constant BPS_DENOMINATOR = 10000;

    event ItemListed(address indexed tokenContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemCanceled(address indexed tokenContract, uint256 indexed tokenId, address indexed seller);
    event ItemUpdated(address indexed tokenContract, uint256 indexed tokenId, address indexed seller, uint256 newPrice);
    event ItemSold(address indexed tokenContract, uint256 indexed tokenId, address indexed buyer, address seller, uint256 price, uint256 royaltyPaid, address royaltyRecipient, uint256 platformFee);
    event PlatformFeeUpdated(uint256 newBps);

    constructor(uint256 _platformFeeBps) {
        require(_platformFeeBps <= 1000, "fee too high");
        platformFeeBps = _platformFeeBps;
    }

    function listItem(address tokenContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be > 0");
        IERC721 token = IERC721(tokenContract);
        address tokenOwner = token.ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Only owner can list");
        address approved = token.getApproved(tokenId);
        bool operatorApproved = token.isApprovedForAll(msg.sender, address(this));
        require(approved == address(this) || operatorApproved, "Marketplace not approved");

        listings[tokenContract][tokenId] = Listing({seller: msg.sender, price: price});
        emit ItemListed(tokenContract, tokenId, msg.sender, price);
    }

    function cancelListing(address tokenContract, uint256 tokenId) external {
        Listing memory l = listings[tokenContract][tokenId];
        require(l.seller != address(0), "Not listed");
        require(l.seller == msg.sender, "Only seller can cancel");
        delete listings[tokenContract][tokenId];
        emit ItemCanceled(tokenContract, tokenId, msg.sender);
    }

    function updateListing(address tokenContract, uint256 tokenId, uint256 newPrice) external {
        require(newPrice > 0, "Price must be > 0");
        Listing storage l = listings[tokenContract][tokenId];
        require(l.seller != address(0), "Not listed");
        require(l.seller == msg.sender, "Only seller can update");
        l.price = newPrice;
        emit ItemUpdated(tokenContract, tokenId, msg.sender, newPrice);
    }

    function getListing(address tokenContract, uint256 tokenId) external view returns (address seller, uint256 price) {
        Listing memory l = listings[tokenContract][tokenId];
        return (l.seller, l.price);
    }

    function buyItem(address tokenContract, uint256 tokenId) external payable nonReentrant {
        Listing memory l = listings[tokenContract][tokenId];
        require(l.seller != address(0), "Not listed");
        require(msg.value == l.price, "Incorrect ETH amount");
        address seller = l.seller;
        require(seller != msg.sender, "Seller cannot buy their own item");

        delete listings[tokenContract][tokenId];

        uint256 salePrice = msg.value;
        uint256 platformFee = (salePrice * platformFeeBps) / BPS_DENOMINATOR;
        uint256 royaltyPaid = 0;
        address royaltyRecipient = address(0);
        uint256 sellerProceeds = salePrice;

        if (IERC165(tokenContract).supportsInterface(type(IERC2981).interfaceId)) {
            try IERC2981(tokenContract).royaltyInfo(tokenId, salePrice) returns (address receiver, uint256 royaltyAmount) {
                if (receiver != address(0) && royaltyAmount > 0 && royaltyAmount < salePrice) {
                    royaltyPaid = royaltyAmount;
                    royaltyRecipient = receiver;
                    sellerProceeds = sellerProceeds - royaltyPaid;
                }
            } catch {}
        }

        if (platformFee > 0) {
            sellerProceeds = (sellerProceeds >= platformFee) ? (sellerProceeds - platformFee) : 0;
        }

        if (royaltyPaid > 0 && royaltyRecipient != address(0)) {
            (bool r1, ) = payable(royaltyRecipient).call{value: royaltyPaid}("");
            require(r1, "Royalty transfer failed");
        }

        if (platformFee > 0) {
            (bool r2, ) = payable(owner).call{value: platformFee}("");
            require(r2, "Platform fee transfer failed");
        }

        if (sellerProceeds > 0) {
            (bool r3, ) = payable(seller).call{value: sellerProceeds}("");
            require(r3, "Seller transfer failed");
        }

        IERC721(tokenContract).safeTransferFrom(seller, msg.sender, tokenId);

        emit ItemSold(tokenContract, tokenId, msg.sender, seller, salePrice, royaltyPaid, royaltyRecipient, platformFee);
    }

    function setPlatformFeeBps(uint256 newBps) external onlyOwner {
        require(newBps <= 1000, "fee too high");
        platformFeeBps = newBps;
        emit PlatformFeeUpdated(newBps);
    }

    function withdrawETH(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero address");
        (bool s, ) = payable(to).call{value: amount}("");
        require(s, "withdraw failed");
    }

    function rescueERC721(address tokenContract, uint256 tokenId, address to) external onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId);
    }

    receive() external payable {}
    fallback() external payable {}
}
