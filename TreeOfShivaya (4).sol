// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreeOfShivaya {
    string public name = "Tree of Shivaya";
    string public symbol = "SHIVAYA";
    uint8 public decimals = 18;
    uint256 public immutable totalSupply;
    uint256 public constant reservedForMining = 420_000_000_000 * 1e18;
    uint256 public constant nowClaimLimit = 300_000_000_000 * 1e18;
    uint256 public constant futureClaimLimit = 120_000_000_000 * 1e18;
    uint256 public distributedNow = 0;
    uint256 public distributedFuture = 0;

    uint256 public futureStart = 1956528000; // Jan 1, 2032
    mapping(address => bool) public hasClaimedNow;
    mapping(address => bool) public isEligibleForFutureMining;
    mapping(address => uint256) public lastFutureClaim;
    mapping(bytes32 => bool) public usedIP;

    address public owner;

    // ✅ Socials
    string public twitter;
    string public website;
    string public telegram;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ClaimedNow(address indexed user, uint256 amount);
    event ClaimedFuture(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
        totalSupply = 920_000_000_000 * 1e18;
        uint256 ownerShare = totalSupply - reservedForMining;
        balanceOf[owner] = ownerShare;
        emit Transfer(address(0), owner, ownerShare);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setTwitter(string memory _twitter) public onlyOwner {
        twitter = _twitter;
    }

    function setWebsite(string memory _website) public onlyOwner {
        website = _website;
    }

    function setTelegram(string memory _telegram) public onlyOwner {
        telegram = _telegram;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Transfer(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient");
        require(allowance[from][msg.sender] >= value, "Not allowed");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function claimNow(string memory ip) public returns (bool) {
        require(!hasClaimedNow[msg.sender], "Already claimed");
        bytes32 ipHash = keccak256(abi.encodePacked(ip));
        require(!usedIP[ipHash], "IP already used");
        require(distributedNow + 1_000_000 * 1e18 <= nowClaimLimit, "Claim limit reached");

        hasClaimedNow[msg.sender] = true;
        isEligibleForFutureMining[msg.sender] = true;
        usedIP[ipHash] = true;

        distributedNow += 1_000_000 * 1e18;
        balanceOf[msg.sender] += 1_000_000 * 1e18;

        emit ClaimedNow(msg.sender, 1_000_000 * 1e18);
        emit Transfer(address(0), msg.sender, 1_000_000 * 1e18);
        return true;
    }

    function claimFuture() public returns (bool) {
        require(block.timestamp >= futureStart, "Future mining not started yet");
        require(isEligibleForFutureMining[msg.sender], "Not eligible");
        require(block.timestamp - lastFutureClaim[msg.sender] >= 365 days, "Only 1 claim per year");

        uint256 yearsPassed = (block.timestamp - futureStart) / 365 days;
        uint256 baseReward = 500_000 * 1e18;
        uint256 reward = baseReward >> (yearsPassed / 2); // halve every 2 years

        require(reward > 0, "Reward finished");
        require(distributedFuture + reward <= futureClaimLimit, "No more future supply");

        distributedFuture += reward;
        lastFutureClaim[msg.sender] = block.timestamp;
        balanceOf[msg.sender] += reward;

        emit ClaimedFuture(msg.sender, reward);
        emit Transfer(address(0), msg.sender, reward);
        return true;
    }
}
