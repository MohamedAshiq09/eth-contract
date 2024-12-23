// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// LearnopolyCertificate contract
contract LearnopolyCertificate is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter; // Keeps track of token IDs

    // Event emitted when a certificate is issued
    event CertificateIssued(address indexed recipient, uint256 indexed tokenId, string tokenURI);

    // Constructor initializing the ERC721 token name, symbol, and setting the initial owner
    constructor() ERC721("LearnopolyCertificate", "LNC") Ownable(msg.sender) {}

    /**
     * @dev Mint a new certificate NFT to the recipient.
     * @param recipient The address of the user receiving the certificate.
     * @param tokenURI The metadata URI for the certificate (e.g., IPFS URL).
     */
    function mintCertificate(address recipient, string memory tokenURI) public onlyOwner {
        require(recipient != address(0), "Invalid recipient address");

        // Increment the token ID counter
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        // Mint the NFT to the recipient
        _mint(recipient, newTokenId);

        // Set the token URI (metadata URL)
        _setTokenURI(newTokenId, tokenURI);

        // Emit the CertificateIssued event
        emit CertificateIssued(recipient, newTokenId, tokenURI);
    }

    /**
     * @dev Get the current token counter.
     * Useful for checking the total number of certificates issued.
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }
}
