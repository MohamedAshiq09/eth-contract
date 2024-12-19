// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Learnopoly {
    struct User {
        address walletAddress;
        string name;
        string role; 
        uint256[] enrolledCourses;
        uint256[] enrolledHackathons;
    }

    struct Course {
        uint256 id;
        string title;
        uint256 price;
        address creator;
        address[] students;
    }

    struct Hackathon {
        uint256 id;
        string name;
        uint256 registrationFee;
        uint256 prizePool;
        address organizer;
        address[] participants;
        bool isActive;
    }

    address public owner;
    uint256 public courseCounter;
    uint256 public hackathonCounter;
    mapping(address => User) public users;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Hackathon) public hackathons;

    event UserRegistered(address user, string name, string role);
    event CourseCreated(uint256 id, string title, address creator);
    event HackathonCreated(uint256 id, string name, address organizer);
    event CourseEnrolled(uint256 courseId, address student);
    event HackathonJoined(uint256 hackathonId, address participant);
    event PrizeDistributed(uint256 hackathonId, address winner, uint256 prize);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyCreator(uint256 courseId) {
        require(
            courses[courseId].creator == msg.sender,
            "Only course creator can perform this action"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCourse(string memory title, uint256 price) external {
        courseCounter++;
        Course storage newCourse = courses[courseCounter];
        newCourse.id = courseCounter;
        newCourse.title = title;
        newCourse.price = price;
        newCourse.creator = msg.sender;

        emit CourseCreated(courseCounter, title, msg.sender);
    }

    function enrollInCourse(uint256 courseId) external payable {
        Course storage course = courses[courseId];
        require(msg.value == course.price, "Incorrect course fee");

        course.students.push(msg.sender);
        users[msg.sender].enrolledCourses.push(courseId);

        payable(course.creator).transfer(msg.value);
        emit CourseEnrolled(courseId, msg.sender);
    }

    function createHackathon(
        string memory name,
        uint256 registrationFee,
        uint256 prizePool
    ) external {
        hackathonCounter++;
        Hackathon storage newHackathon = hackathons[hackathonCounter];
        newHackathon.id = hackathonCounter;
        newHackathon.name = name;
        newHackathon.registrationFee = registrationFee;
        newHackathon.prizePool = prizePool;
        newHackathon.organizer = msg.sender;
        newHackathon.isActive = true;

        emit HackathonCreated(hackathonCounter, name, msg.sender);
    }

    function joinHackathon(uint256 hackathonId) external payable {
        Hackathon storage hackathon = hackathons[hackathonId];
        require(hackathon.isActive, "Hackathon is not active");
        require(
            msg.value == hackathon.registrationFee,
            "Incorrect registration fee"
        );

        hackathon.participants.push(msg.sender);
        users[msg.sender].enrolledHackathons.push(hackathonId);

        emit HackathonJoined(hackathonId, msg.sender);
    }

    function distributePrize(uint256 hackathonId, address winner) external onlyOwner {
        Hackathon storage hackathon = hackathons[hackathonId];
        require(hackathon.isActive, "Hackathon is not active");
        require(
            address(this).balance >= hackathon.prizePool,
            "Insufficient contract balance"
        );

        hackathon.isActive = false;
        payable(winner).transfer(hackathon.prizePool);
        emit PrizeDistributed(hackathonId, winner, hackathon.prizePool);
    }

    function getCourseStudents(uint256 courseId)
        external
        view
        returns (address[] memory)
    {
        return courses[courseId].students;
    }

    function getHackathonParticipants(uint256 hackathonId)
        external
        view
        returns (address[] memory)
    {
        return hackathons[hackathonId].participants;
    }

    function getUserEnrolledCourses(address user)
        external
        view
        returns (uint256[] memory)
    {
        return users[user].enrolledCourses;
    }

    function getUserEnrolledHackathons(address user)
        external
        view
        returns (uint256[] memory)
    {
        return users[user].enrolledHackathons;
    }

    
    receive() external payable {}
}
