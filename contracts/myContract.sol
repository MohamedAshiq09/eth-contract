// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Learnopoly {
    struct User {
        address walletAddress;
        string name;
        string role; 
        uint256[] enrolledHackathons;
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
    uint256 public hackathonCounter;
    mapping(address => User) public users;
    mapping(uint256 => Hackathon) public hackathons;

    event HackathonCreated(uint256 id, string name, address organizer);
    event UserRegistered(address user, string name, string role);
    event HackathonJoined(uint256 hackathonId, address participant);
    event PrizeDistributed(uint256 hackathonId, address winner, uint256 prize);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyOrganizer(uint256 hackathonId) {
        require(
            hackathons[hackathonId].organizer == msg.sender,
            "Only organizer can perform this action"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerUser(string memory name, string memory role) external {
        require(bytes(users[msg.sender].name).length == 0, "User already registered");
        users[msg.sender] = User(msg.sender, name, role, new uint256[](0));
        emit UserRegistered(msg.sender, name, role);
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

    function distributePrize(uint256 hackathonId, address winner) external onlyOrganizer(hackathonId) {
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

    function getHackathonParticipants(uint256 hackathonId)
        external
        view
        returns (address[] memory)
    {
        return hackathons[hackathonId].participants;
    }

    function getEnrolledHackathons(address user)
        external
        view
        returns (uint256[] memory)
    {
        return users[user].enrolledHackathons;
    }

    
    receive() external payable {}
}
