// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract LearnopolyCertificate is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Certificate {
        string courseName;
        address student;
        uint256 issueDate;
        string ipfsHash;  
        bool verified;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => bool) public authorizedIssuers;

    event CertificateIssued(uint256 tokenId, address student, string courseName);
    event IssuerAuthorized(address issuer);

    constructor(address initialOwner)
        ERC721("LearnopolyCertificate", "LCERT")
        Ownable(initialOwner)
    {}

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not authorized to issue certificates");
        _;
    }

    function authorizeIssuer(address issuer) external onlyOwner {
        authorizedIssuers[issuer] = true;
        emit IssuerAuthorized(issuer);
    }

    function issueCertificate(
        address student,
        string memory courseName,
        string memory ipfsHash
    ) external onlyAuthorizedIssuer returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        certificates[newTokenId] = Certificate({
            courseName: courseName,
            student: student,
            issueDate: block.timestamp,
            ipfsHash: ipfsHash,
            verified: true
        });

        _mint(student, newTokenId);
        emit CertificateIssued(newTokenId, student, courseName);
        return newTokenId;
    }
}

contract LearningProgress is Ownable {
    struct Achievement {
        string skillName;
        uint256 level;
        uint256 timestamp;
        bool verified;
    }

    mapping(address => Achievement[]) public userAchievements;
    mapping(address => mapping(string => bool)) public completedCourses;
    mapping(address => bool) public authorizedUpdaters;

    event ProgressUpdated(address student, string skillName, uint256 level);
    event CourseCompleted(address student, string courseName);
    event UpdaterAuthorized(address updater);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier onlyAuthorizedUpdater() {
        require(authorizedUpdaters[msg.sender], "Not authorized to update progress");
        _;
    }

    function authorizeUpdater(address updater) external onlyOwner {
        authorizedUpdaters[updater] = true;
        emit UpdaterAuthorized(updater);
    }

    function updateProgress(
        address student,
        string memory skillName,
        uint256 level
    ) external onlyAuthorizedUpdater {
        Achievement memory newAchievement = Achievement({
            skillName: skillName,
            level: level,
            timestamp: block.timestamp,
            verified: true
        });
        
        userAchievements[student].push(newAchievement);
        emit ProgressUpdated(student, skillName, level);
    }

    function markCourseComplete(address student, string memory courseName) external onlyAuthorizedUpdater {
        completedCourses[student][courseName] = true;
        emit CourseCompleted(student, courseName);
    }

    function getAchievements(address student) external view returns (Achievement[] memory) {
        return userAchievements[student];
    }
}

contract LearnopolyToken is ERC20, Ownable {
    mapping(address => bool) public authorizedMinters;

    event MinterAuthorized(address minter);

    constructor(address initialOwner) 
        ERC20("LearnopolyToken", "LEARN")
        Ownable(initialOwner)
    {}

    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender], "Not authorized to mint tokens");
        _;
    }

    function authorizeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
        emit MinterAuthorized(minter);
    }

    function mintReward(address student, uint256 amount) external onlyAuthorizedMinter {
        _mint(student, amount);
    }
}

contract SkillEndorsement is Ownable {
    struct Endorsement {
        address endorser;
        string skill;
        uint256 rating;  // 1-5 scale
        string comment;
        uint256 timestamp;
    }

    mapping(address => Endorsement[]) public userEndorsements;
    mapping(address => mapping(address => mapping(string => bool))) public hasEndorsed;

    event SkillEndorsed(address indexed endorsed, address indexed endorser, string skill, uint256 rating);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function endorseSkill(
        address user,
        string memory skill,
        uint256 rating,
        string memory comment
    ) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(!hasEndorsed[msg.sender][user][skill], "Already endorsed this skill");
        require(msg.sender != user, "Cannot endorse yourself");
        
        Endorsement memory newEndorsement = Endorsement({
            endorser: msg.sender,
            skill: skill,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        });
        
        userEndorsements[user].push(newEndorsement);
        hasEndorsed[msg.sender][user][skill] = true;
        
        emit SkillEndorsed(user, msg.sender, skill, rating);
    }

    function getEndorsements(address user) external view returns (Endorsement[] memory) {
        return userEndorsements[user];
    }
}