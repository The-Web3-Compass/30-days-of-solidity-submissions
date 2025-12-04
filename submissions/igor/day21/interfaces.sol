interface IERC721{
    function balanceOf(address owner) external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);

    function approve(address to,uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner,address operator) external view returns(bool);

    function transferFrom(address from,address to,uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}