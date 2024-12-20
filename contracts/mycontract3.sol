// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Learnopoly {
    // Structs
    struct User {
        address walletAddress;
        string username;
        string role; // "student", "professional", etc.
        uint256[] purchasedCourses;
        uint256 earnedPoints;
    }

    struct Course {
        uint256 id;
        string title;
        string description;
        uint256 price; // In Wei
        address instructor;
    }

    // Events
    event UserRegistered(address indexed walletAddress, string username, string role);
    event CourseCreated(uint256 indexed courseId, string title, uint256 price, address indexed instructor);
    event CoursePurchased(address indexed buyer, uint256 indexed courseId);
    event PointsEarned(address indexed user, uint256 points);

    // Mappings
    mapping(address => User) public users; // Maps wallet address to User struct
    mapping(uint256 => Course) public courses; // Maps course ID to Course struct
    mapping(address => uint256[]) public instructorCourses; // Maps instructor to their created courses

    // State variables
    uint256 public courseCount;
    address public owner;

    // Modifiers
    modifier onlyRegisteredUser() {
        require(bytes(users[msg.sender].username).length > 0, "User not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender; // Deployer is the owner
    }

    // Register a new user
    function registerUser(string memory username, string memory role) external {
        require(bytes(users[msg.sender].username).length == 0, "User already registered");
        
        uint256[] memory emptyCourses = new uint256[](0);
        
        users[msg.sender] = User({
            walletAddress: msg.sender,
            username: username,
            role: role,
            purchasedCourses: emptyCourses,
            earnedPoints: 0
        });
        
        emit UserRegistered(msg.sender, username, role);
    }

    // Create a new course (by instructor)
    function createCourse(
        string memory title,
        string memory description,
        uint256 price
    ) external onlyRegisteredUser {
        require(price > 0, "Price must be greater than zero");
        require(
            keccak256(abi.encodePacked(users[msg.sender].role)) == 
            keccak256(abi.encodePacked("instructor")),
            "Only instructors can create courses"
        );
        
        courseCount++;
        
        courses[courseCount] = Course({
            id: courseCount,
            title: title,
            description: description,
            price: price,
            instructor: msg.sender
        });
        
        instructorCourses[msg.sender].push(courseCount);
        
        emit CourseCreated(courseCount, title, price, msg.sender);
    }

    // Purchase a course
    function purchaseCourse(uint256 courseId) external payable onlyRegisteredUser {
        Course memory course = courses[courseId];
        require(course.id > 0, "Course does not exist");
        require(msg.value == course.price, "Incorrect payment amount");

        payable(course.instructor).transfer(msg.value);
        users[msg.sender].purchasedCourses.push(courseId);
        
        emit CoursePurchased(msg.sender, courseId);
    }

    // Earn points for completing activities
    function earnPoints(uint256 points) external onlyRegisteredUser {
        require(points > 0, "Points must be greater than zero");
        users[msg.sender].earnedPoints += points;
        
        emit PointsEarned(msg.sender, points);
    }

    // Retrieve user profile
    function getUserProfile(address userAddress)
        external
        view
        returns (
            string memory username,
            string memory role,
            uint256[] memory purchasedCourses,
            uint256 earnedPoints
        )
    {
        User memory user = users[userAddress];
        return (user.username, user.role, user.purchasedCourses, user.earnedPoints);
    }

    // Get course details
    function getCourseDetails(uint256 courseId)
        external
        view
        returns (
            string memory title,
            string memory description,
            uint256 price,
            address instructor
        )
    {
        Course memory course = courses[courseId];
        return (course.title, course.description, course.price, course.instructor);
    }

    // Owner-only function to withdraw contract balance
    function withdrawBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Fallback function to accept ETH payments
    receive() external payable {}
}