// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC4494 {
    // permit signature for ERC721 token
    function permit(address spender, uint256 tokenId, uint256 deadline, bytes calldata signature) external;
    function get_nonces(uint256 tokenId) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}