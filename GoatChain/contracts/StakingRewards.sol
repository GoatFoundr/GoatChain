// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title StakingRewards
/// @notice Allows fans to stake an artist token and earn GOATCHAIN rewards.
contract StakingRewards is ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    IERC20 public stakingToken; // Artist Token
    IERC20 public rewardToken;  // GOATCHAIN

    uint256 public rewardRate;         // reward tokens distributed per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    event RewardAdded(uint256 rewardAmount, uint256 duration);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function initialize(address _stakingToken, address _rewardToken) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    // ============ External Functions ============

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "stake=0");
        totalSupply += amount;
        balances[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "transfer fail");
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "withdraw=0");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "transfer fail");
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardToken.transfer(msg.sender, reward), "reward transfer fail");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    // ============ Rewards Distribution ============

    /// @notice Fund rewards with a set duration.
    /// @param reward Amount of reward tokens to distribute.
    /// @param duration Duration in seconds over which rewards are distributed.
    function notifyRewardAmount(uint256 reward, uint256 duration) external onlyOwner updateReward(address(0)) {
        require(reward > 0 && duration > 0, "invalid params");
        require(rewardToken.transferFrom(msg.sender, address(this), reward), "funding fail");
        if (block.timestamp >= lastUpdateTime) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = lastUpdateTime + duration - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / duration;
        }
        lastUpdateTime = block.timestamp;

        emit RewardAdded(reward, duration);
    }

    // ============ View Functions ============

    function earned(address account) public view returns (uint256) {
        return ((balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 timeDelta = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (timeDelta * rewardRate * 1e18) / totalSupply;
    }

    // ============ Modifiers ============

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 