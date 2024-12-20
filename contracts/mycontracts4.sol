// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Main Learnopoly Platform Contract
contract LearnopolyPlatform is ReentrancyGuard, Ownable {
    // Structs
    struct Profile {
        string username;
        string role;
        string bio;
        string[] skills;
        address[] connections;
        uint256[] completedCourses;
        uint256[] earnedBadges;
        uint256 reputation;
        bool isMentor;
    }

    struct Course {
        uint256 id;
        address instructor;
        string title;
        string description;
        uint256 price;
        string[] modules;
        uint256 enrollmentCount;
        mapping(address => bool) enrolled;
        mapping(address => uint256) progress;
        uint256 rating;
        uint256 ratingCount;
    }

    struct Event {
        uint256 id;
        string title;
        string description;
        uint256 timestamp;
        uint256 capacity;
        uint256 price;
        address host;
        mapping(address => bool) participants;
        uint256 participantCount;
    }

    struct Job {
        uint256 id;
        address company;
        string title;
        string description;
        string[] requiredSkills;
        uint256 salary;
        bool isActive;
        uint256 deadline;
    }

    // State Variables
    mapping(address => Profile) public profiles;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Event) public events;
    mapping(uint256 => Job) public jobs;
    
    uint256 public courseCount;
    uint256 public eventCount;
    uint256 public jobCount;
    uint256 public badgeCount;

    // Events
    event ProfileCreated(address indexed user, string username, string role);
    event CourseCreated(uint256 indexed courseId, address instructor, string title);
    event CourseEnrolled(uint256 indexed courseId, address indexed student);
    event EventCreated(uint256 indexed eventId, string title, address host);
    event EventJoined(uint256 indexed eventId, address indexed participant);
    event JobPosted(uint256 indexed jobId, address indexed company, string title);
    event BadgeEarned(address indexed user, uint256 indexed badgeId);
    event MentorshipRequested(address indexed mentee, address indexed mentor);
    event ConnectionMade(address indexed user1, address indexed user2);

    
    constructor(address initialOwner) Ownable(initialOwner) {
        courseCount = 0;
        eventCount = 0;
        jobCount = 0;
        badgeCount = 0;
    }

    
    modifier onlyRegistered() {
        require(bytes(profiles[msg.sender].username).length > 0, "Not registered");
        _;
    }

    modifier onlyMentor() {
        require(profiles[msg.sender].isMentor, "Not a mentor");
        _;
    }

   
    function createProfile(
        string memory username,
        string memory role,
        string memory bio,
        string[] memory skills
    ) external {
        require(bytes(profiles[msg.sender].username).length == 0, "Profile exists");
        
        profiles[msg.sender].username = username;
        profiles[msg.sender].role = role;
        profiles[msg.sender].bio = bio;
        profiles[msg.sender].skills = skills;
        profiles[msg.sender].reputation = 0;
        
        emit ProfileCreated(msg.sender, username, role);
    }

    
    function createCourse(
        string memory title,
        string memory description,
        uint256 price,
        string[] memory modules
    ) external onlyRegistered nonReentrant {
        courseCount++;
        Course storage newCourse = courses[courseCount];
        
        newCourse.id = courseCount;
        newCourse.instructor = msg.sender;
        newCourse.title = title;
        newCourse.description = description;
        newCourse.price = price;
        newCourse.modules = modules;
        newCourse.enrollmentCount = 0;
        newCourse.rating = 0;
        newCourse.ratingCount = 0;
        
        emit CourseCreated(courseCount, msg.sender, title);
    }

    function enrollInCourse(uint256 courseId) external payable onlyRegistered nonReentrant {
        Course storage course = courses[courseId];
        require(course.id != 0, "Course doesn't exist");
        require(!course.enrolled[msg.sender], "Already enrolled");
        require(msg.value == course.price, "Incorrect payment");

        course.enrolled[msg.sender] = true;
        course.enrollmentCount++;
        profiles[msg.sender].completedCourses.push(courseId);

        payable(course.instructor).transfer(msg.value);
        emit CourseEnrolled(courseId, msg.sender);
    }

    
    function createEvent(
        string memory title,
        string memory description,
        uint256 timestamp,
        uint256 capacity,
        uint256 price
    ) external onlyRegistered {
        require(timestamp > block.timestamp, "Invalid timestamp");
        eventCount++;
        Event storage newEvent = events[eventCount];
        
        newEvent.id = eventCount;
        newEvent.title = title;
        newEvent.description = description;
        newEvent.timestamp = timestamp;
        newEvent.capacity = capacity;
        newEvent.price = price;
        newEvent.host = msg.sender;
        newEvent.participantCount = 0;
        
        emit EventCreated(eventCount, title, msg.sender);
    }

    // Job Board Functions
    function postJob(
        string memory title,
        string memory description,
        string[] memory requiredSkills,
        uint256 salary,
        uint256 deadline
    ) external onlyRegistered {
        require(deadline > block.timestamp, "Invalid deadline");
        jobCount++;
        Job storage newJob = jobs[jobCount];
        
        newJob.id = jobCount;
        newJob.company = msg.sender;
        newJob.title = title;
        newJob.description = description;
        newJob.requiredSkills = requiredSkills;
        newJob.salary = salary;
        newJob.deadline = deadline;
        newJob.isActive = true;
        
        emit JobPosted(jobCount, msg.sender, title);
    }

    // Networking Functions
    function addConnection(address user) external onlyRegistered {
        require(user != msg.sender, "Cannot connect to self");
        require(bytes(profiles[user].username).length > 0, "User not registered");
        
        profiles[msg.sender].connections.push(user);
        profiles[user].connections.push(msg.sender);
        
        emit ConnectionMade(msg.sender, user);
    }

    // Mentorship Functions
    function becomeMentor() external onlyRegistered {
        require(!profiles[msg.sender].isMentor, "Already a mentor");
        require(profiles[msg.sender].reputation >= 100, "Insufficient reputation");
        
        profiles[msg.sender].isMentor = true;
    }

    // Reputation and Rewards
    function awardBadge(address user, uint256 badgeId) external onlyOwner {
        require(bytes(profiles[user].username).length > 0, "User not registered");
        profiles[user].earnedBadges.push(badgeId);
        profiles[user].reputation += 10;
        
        emit BadgeEarned(user, badgeId);
    }

    // View Functions
    function getProfile(address user) external view returns (
        string memory username,
        string memory role,
        string memory bio,
        uint256 reputation,
        bool isMentor
    ) {
        Profile storage profile = profiles[user];
        return (
            profile.username,
            profile.role,
            profile.bio,
            profile.reputation,
            profile.isMentor
        );
    }

    // Utility Functions
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }

    receive() external payable {}
}

// Badge NFT Contract
contract LearnopolyBadge is ERC721 {
    uint256 private _tokenIds;
    address private platformAddress;

    constructor(address initialPlatform) ERC721("LearnopolyBadge", "LBADGE") {
        platformAddress = initialPlatform;
    }

    function mintBadge(address recipient) external returns (uint256) {
        require(msg.sender == platformAddress, "Only platform can mint");
        _tokenIds++;
        _mint(recipient, _tokenIds);
        return _tokenIds;
    }
}