// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoatRewards is ReentrancyGuard, Ownable {
    struct Reward {
        string rewardType; // "unreleased_song", "meet_and_greet", "exclusive_content", etc.
        string contentHash; // IPFS hash of the content
        uint256 requiredStake;
        uint256 expiryTime;
        bool isActive;
        uint256 totalClaims;
    }
    
    struct ArtistProfile {
        bool isVerified;
        string metadata; // IPFS hash for artist profile
        uint256 totalRewards;
        uint256 totalClaims;
    }
    
    struct UserReward {
        bool hasClaimed;
        uint256 claimTime;
    }
    
    // Platform fee settings
    uint256 public platformFee = 100; // 1%
    uint256 public constant BASIS_POINTS = 10000;
    
    mapping(address => ArtistProfile) public artists;
    mapping(address => mapping(uint256 => Reward)) public rewards; // artist => rewardId => reward
    mapping(address => mapping(address => mapping(uint256 => UserReward))) public userRewards; // user => artist => rewardId => userReward
    
    event ArtistVerified(address indexed artist, string metadata);
    event RewardCreated(address indexed artist, uint256 rewardId, string rewardType, uint256 requiredStake);
    event RewardClaimed(address indexed user, address indexed artist, uint256 rewardId);
    event ContentUpdated(address indexed artist, uint256 rewardId, string contentHash);
    
    constructor() Ownable(msg.sender) {}
    
    function verifyArtist(address _artist, string memory _metadata) external onlyOwner {
        require(!artists[_artist].isVerified, "Artist already verified");
        
        artists[_artist] = ArtistProfile({
            isVerified: true,
            metadata: _metadata,
            totalRewards: 0,
            totalClaims: 0
        });
        
        emit ArtistVerified(_artist, _metadata);
    }
    
    function createReward(
        string memory _rewardType,
        string memory _contentHash,
        uint256 _requiredStake,
        uint256 _expiryTime
    ) external {
        require(artists[msg.sender].isVerified, "Not a verified artist");
        require(_requiredStake > 0, "Invalid stake amount");
        require(_expiryTime > block.timestamp, "Invalid expiry time");
        
        uint256 rewardId = artists[msg.sender].totalRewards;
        
        rewards[msg.sender][rewardId] = Reward({
            rewardType: _rewardType,
            contentHash: _contentHash,
            requiredStake: _requiredStake,
            expiryTime: _expiryTime,
            isActive: true,
            totalClaims: 0
        });
        
        artists[msg.sender].totalRewards++;
        
        emit RewardCreated(msg.sender, rewardId, _rewardType, _requiredStake);
    }
    
    function updateContent(
        uint256 _rewardId,
        string memory _contentHash
    ) external {
        require(artists[msg.sender].isVerified, "Not a verified artist");
        require(rewards[msg.sender][_rewardId].isActive, "Reward not active");
        
        rewards[msg.sender][_rewardId].contentHash = _contentHash;
        
        emit ContentUpdated(msg.sender, _rewardId, _contentHash);
    }
    
    function claimReward(
        address _artist,
        uint256 _rewardId,
        address _token
    ) external nonReentrant {
        require(artists[_artist].isVerified, "Artist not verified");
        Reward storage reward = rewards[_artist][_rewardId];
        require(reward.isActive, "Reward not active");
        require(block.timestamp <= reward.expiryTime, "Reward expired");
        require(!userRewards[msg.sender][_artist][_rewardId].hasClaimed, "Already claimed");
        
        // Check if user has staked enough
        uint256 userStake = getUserStake(msg.sender, _token);
        require(userStake >= reward.requiredStake, "Insufficient stake");
        
        // Update claim status
        userRewards[msg.sender][_artist][_rewardId] = UserReward({
            hasClaimed: true,
            claimTime: block.timestamp
        });
        
        reward.totalClaims++;
        artists[_artist].totalClaims++;
        
        emit RewardClaimed(msg.sender, _artist, _rewardId);
    }
    
    function getUserStake(address _user, address _token) public view returns (uint256) {
        // This would need to be implemented to get the user's stake from the staking contract
        return 0; // Placeholder
    }
    
    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= 500, "Fee too high"); // Max 5%
        platformFee = _fee;
    }
} 