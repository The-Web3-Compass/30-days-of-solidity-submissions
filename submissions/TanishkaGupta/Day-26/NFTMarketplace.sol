// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMarketplace {

    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }

    uint256 public listingCount;
    uint256 public royaltyPercent = 5; // 5% royalty

    mapping(uint256 => Listing) public listings;

    event Listed(uint256 listingId, address seller, uint256 price);
    event Bought(uint256 listingId, address buyer);
    event Cancelled(uint256 listingId);

    /*
     * List NFT for sale
     */
    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) external {

        require(_price > 0, "Price must be greater than 0");

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        listingCount++;

        listings[listingCount] = Listing({
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price
        });

        emit Listed(listingCount, msg.sender, _price);
    }

    /*
     * Buy NFT
     */
    function buyNFT(uint256 listingId) external payable {

        Listing memory item = listings[listingId];

        require(item.price > 0, "Invalid listing");
        require(msg.value >= item.price, "Insufficient payment");

        uint256 royalty = (item.price * royaltyPercent) / 100;
        uint256 sellerAmount = item.price - royalty;

        // Transfer funds
        payable(item.seller).transfer(sellerAmount);

        // Transfer NFT
        IERC721(item.nftContract).transferFrom(address(this), msg.sender, item.tokenId);

        delete listings[listingId];

        emit Bought(listingId, msg.sender);
    }

    /*
     * Cancel listing
     */
    function cancelListing(uint256 listingId) external {

        Listing memory item = listings[listingId];

        require(item.seller == msg.sender, "Not seller");

        IERC721(item.nftContract).transferFrom(address(this), msg.sender, item.tokenId);

        delete listings[listingId];

        emit Cancelled(listingId);
    }

    /*
     * Update royalty
     */
    function setRoyalty(uint256 _percent) external {
        require(_percent <= 10, "Max 10%");
        royaltyPercent = _percent;
    }
}