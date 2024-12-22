// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LearnopolyCertificate is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter; // 

    event CertificateIssued(address indexed recipient, uint256 indexed tokenId, string tokenURI);

    constructor() ERC721("LearnopolyCertificate", "LNC") public {
        _tokenIdCounter = 0;
    }

    function mintCertificate(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        require(recipient != address(0), "Recipient cannot be the zero address");

        // Increment the token ID counter
        uint256 newTokenId = _tokenIdCounter + 1; 
        _tokenIdCounter += 1;

        // Mint the NFT and set its metadata URI
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // Emit the event to signal certificate issuance
        emit CertificateIssued(recipient, newTokenId, tokenURI);

        return newTokenId;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter + 1; 
    }
}