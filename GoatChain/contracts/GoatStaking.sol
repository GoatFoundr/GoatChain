// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoatStaking is ReentrancyGuard, Ownable {
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardRate;
        uint256 lastRewardClaim;
    }
    
    struct Reward {
        string rewardType;  // e.g., "unreleased_song", "meet_and_greet", etc.
        uint256 requiredAmount;
        bool isActive;
    }
    
    // Fee settings
    uint256 public platformFee = 200; // 2% platform fee
    uint256 public artistFee = 100;   // 1% artist fee
    uint256 public stakingRewardFee = 100; // 1% for staking rewards
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_PLATFORM_FEE = 400; // 4% max
    
    address public platformFeeCollector;
    mapping(address => uint256) public stakingRewardPool; // token => amount
    
    mapping(address => mapping(address => Stake)) public stakes; // user => token => stake
    mapping(address => Reward[]) public artistRewards; // artist => rewards
    mapping(address => bool) public isArtist;
    mapping(address => bool) public isPartneredArtist;
    
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardClaimed(address indexed user, address indexed artist, string rewardType);
    event RewardAdded(address indexed artist, string rewardType, uint256 requiredAmount);
    event PlatformFeeCollected(address indexed token, uint256 amount);
    event ArtistFeeCollected(address indexed artist, address indexed token, uint256 amount);
    event StakingRewardAdded(address indexed token, uint256 amount);
    event PartneredArtistAdded(address indexed artist);
    
    constructor() Ownable(msg.sender) {
        platformFeeCollector = msg.sender;
    }
    
    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_PLATFORM_FEE, "Fee too high");
        platformFee = _fee;
    }
    
    function setPlatformFeeCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid address");
        platformFeeCollector = _collector;
    }
    
    function addPartneredArtist(address _artist) external onlyOwner {
        isPartneredArtist[_artist] = true;
        isArtist[_artist] = true;
        emit PartneredArtistAdded(_artist);
    }
    
    function addReward(
        string memory _rewardType,
        uint256 _requiredAmount
    ) external {
        require(isPartneredArtist[msg.sender], "Not a partnered artist");
        artistRewards[msg.sender].push(Reward({
            rewardType: _rewardType,
            requiredAmount: _requiredAmount,
            isActive: true
        }));
        emit RewardAdded(msg.sender, _rewardType, _requiredAmount);
    }
    
    function stake(address _token, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Calculate fees
        uint256 platformFeeAmount = (_amount * platformFee) / BASIS_POINTS;
        uint256 artistFeeAmount = (_amount * artistFee) / BASIS_POINTS;
        uint256 stakingRewardAmount = (_amount * stakingRewardFee) / BASIS_POINTS;
        uint256 stakeAmount = _amount - platformFeeAmount - artistFeeAmount - stakingRewardAmount;
        
        // Transfer tokens
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        
        // Distribute fees
        IERC20(_token).transfer(platformFeeCollector, platformFeeAmount);
        address artist = getArtistFromToken(_token);
        if (artist != address(0)) {
            IERC20(_token).transfer(artist, artistFeeAmount);
        }
        
        // Add to staking reward pool
        stakingRewardPool[_token] += stakingRewardAmount;
        
        // Update stake
        stakes[msg.sender][_token] = Stake({
            amount: stakeAmount,
            timestamp: block.timestamp,
            rewardRate: calculateRewardRate(_token),
            lastRewardClaim: block.timestamp
        });
        
        emit Staked(msg.sender, _token, stakeAmount);
        emit PlatformFeeCollected(_token, platformFeeAmount);
        if (artist != address(0)) {
            emit ArtistFeeCollected(artist, _token, artistFeeAmount);
        }
        emit StakingRewardAdded(_token, stakingRewardAmount);
    }
    
    function claimStakingRewards(address _token) external nonReentrant {
        Stake storage userStake = stakes[msg.sender][_token];
        require(userStake.amount > 0, "No stake found");
        
        uint256 timeStaked = block.timestamp - userStake.lastRewardClaim;
        uint256 rewardAmount = (userStake.amount * userStake.rewardRate * timeStaked) / (365 days);
        
        require(rewardAmount <= stakingRewardPool[_token], "Insufficient reward pool");
        
        stakingRewardPool[_token] -= rewardAmount;
        userStake.lastRewardClaim = block.timestamp;
        
        IERC20(_token).transfer(msg.sender, rewardAmount);
    }
    
    function unstake(address _token) external nonReentrant {
        Stake storage userStake = stakes[msg.sender][_token];
        require(userStake.amount > 0, "No stake found");
        
        // Claim any pending rewards first
        if (userStake.lastRewardClaim < block.timestamp) {
            claimStakingRewards(_token);
        }
        
        uint256 amount = userStake.amount;
        userStake.amount = 0;
        
        IERC20(_token).transfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, _token, amount);
    }
    
    function claimReward(address _artist, uint256 _rewardIndex) external {
        require(_rewardIndex < artistRewards[_artist].length, "Invalid reward index");
        Reward storage reward = artistRewards[_artist][_rewardIndex];
        require(reward.isActive, "Reward not active");
        
        address artistToken = getArtistToken(_artist);
        require(artistToken != address(0), "Artist token not found");
        
        Stake storage userStake = stakes[msg.sender][artistToken];
        require(userStake.amount >= reward.requiredAmount, "Insufficient stake amount");
        
        reward.isActive = false;
        
        emit RewardClaimed(msg.sender, _artist, reward.rewardType);
    }
    
    function getArtistToken(address _artist) public view returns (address) {
        // This would need to be implemented to get the artist's token address
        return address(0); // Placeholder
    }
    
    function getArtistFromToken(address _token) public view returns (address) {
        // This would need to be implemented to get the artist from token
        return address(0); // Placeholder
    }
    
    function calculateRewardRate(address _token) public view returns (uint256) {
        // Calculate APY based on staking pool size and total staked
        // This is a placeholder implementation
        return 1000; // 10% APY
    }
} 