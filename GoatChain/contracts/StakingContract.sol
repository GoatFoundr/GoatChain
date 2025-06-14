// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingContract is ReentrancyGuard, Ownable, Pausable {
    IERC20 public stakingToken;
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardRate;
    }

    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public constant REWARD_RATE = 10; // 10% APY
    uint256 public constant REWARD_INTERVAL = 365 days;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        if (stakes[msg.sender].amount > 0) {
            _payReward(msg.sender);
        }

        stakes[msg.sender] = Stake({
            amount: stakes[msg.sender].amount + amount,
            timestamp: block.timestamp,
            rewardRate: REWARD_RATE
        });

        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake() external nonReentrant whenNotPaused {
        require(stakes[msg.sender].amount > 0, "No stake found");
        
        _payReward(msg.sender);
        
        uint256 amount = stakes[msg.sender].amount;
        totalStaked -= amount;
        delete stakes[msg.sender];

        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function getReward() external nonReentrant whenNotPaused {
        require(stakes[msg.sender].amount > 0, "No stake found");
        _payReward(msg.sender);
    }

    function _payReward(address user) internal {
        Stake storage userStake = stakes[user];
        uint256 reward = calculateReward(user);
        
        if (reward > 0) {
            userStake.timestamp = block.timestamp;
            require(stakingToken.transfer(user, reward), "Reward transfer failed");
            emit RewardPaid(user, reward);
        }
    }

    function calculateReward(address user) public view returns (uint256) {
        Stake storage userStake = stakes[user];
        if (userStake.amount == 0) return 0;

        uint256 timeStaked = block.timestamp - userStake.timestamp;
        return (userStake.amount * userStake.rewardRate * timeStaked) / (REWARD_INTERVAL * 100);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
} 