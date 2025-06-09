// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GoatLiquidityPool is Ownable, ReentrancyGuard {
    IERC20 public goatToken;
    
    struct LiquidityProvider {
        uint256 amount;
        uint256 lastRewardClaim;
        uint256 rewardDebt;
    }
    
    mapping(address => LiquidityProvider) public providers;
    uint256 public totalLiquidity;
    uint256 public rewardPerToken;
    uint256 public lastRewardUpdate;
    
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event RewardsClaimed(address indexed provider, uint256 amount);
    
    constructor(address _goatToken) Ownable(msg.sender) {
        goatToken = IERC20(_goatToken);
        lastRewardUpdate = block.timestamp;
    }
    
    function addLiquidity(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Update rewards
        updateRewards();
        
        // Transfer tokens from provider
        goatToken.transferFrom(msg.sender, address(this), _amount);
        
        // Update provider's liquidity
        LiquidityProvider storage provider = providers[msg.sender];
        provider.amount += _amount;
        provider.rewardDebt = (provider.amount * rewardPerToken) / 1e18;
        
        totalLiquidity += _amount;
        
        emit LiquidityAdded(msg.sender, _amount);
    }
    
    function removeLiquidity(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        LiquidityProvider storage provider = providers[msg.sender];
        require(provider.amount >= _amount, "Insufficient liquidity");
        
        // Update rewards
        updateRewards();
        
        // Calculate and transfer rewards
        uint256 pendingRewards = (provider.amount * rewardPerToken) / 1e18 - provider.rewardDebt;
        if (pendingRewards > 0) {
            goatToken.transfer(msg.sender, pendingRewards);
            emit RewardsClaimed(msg.sender, pendingRewards);
        }
        
        // Update provider's liquidity
        provider.amount -= _amount;
        provider.rewardDebt = (provider.amount * rewardPerToken) / 1e18;
        
        totalLiquidity -= _amount;
        
        // Transfer liquidity back to provider
        goatToken.transfer(msg.sender, _amount);
        
        emit LiquidityRemoved(msg.sender, _amount);
    }
    
    function claimRewards() external nonReentrant {
        LiquidityProvider storage provider = providers[msg.sender];
        require(provider.amount > 0, "No liquidity provided");
        
        // Update rewards
        updateRewards();
        
        // Calculate and transfer rewards
        uint256 pendingRewards = (provider.amount * rewardPerToken) / 1e18 - provider.rewardDebt;
        require(pendingRewards > 0, "No rewards to claim");
        
        provider.rewardDebt = (provider.amount * rewardPerToken) / 1e18;
        provider.lastRewardClaim = block.timestamp;
        
        goatToken.transfer(msg.sender, pendingRewards);
        
        emit RewardsClaimed(msg.sender, pendingRewards);
    }
    
    function updateRewards() public {
        if (totalLiquidity == 0) {
            lastRewardUpdate = block.timestamp;
            return;
        }
        
        uint256 timeElapsed = block.timestamp - lastRewardUpdate;
        if (timeElapsed > 0) {
            // Calculate new rewards (1% APY)
            uint256 newRewards = (totalLiquidity * timeElapsed * 100) / (365 days * 10000);
            rewardPerToken += (newRewards * 1e18) / totalLiquidity;
            lastRewardUpdate = block.timestamp;
        }
    }
    
    function getPendingRewards(address _provider) external view returns (uint256) {
        LiquidityProvider storage provider = providers[_provider];
        if (provider.amount == 0) return 0;
        
        uint256 currentRewardPerToken = rewardPerToken;
        if (totalLiquidity > 0) {
            uint256 timeElapsed = block.timestamp - lastRewardUpdate;
            uint256 newRewards = (totalLiquidity * timeElapsed * 100) / (365 days * 10000);
            currentRewardPerToken += (newRewards * 1e18) / totalLiquidity;
        }
        
        return (provider.amount * currentRewardPerToken) / 1e18 - provider.rewardDebt;
    }
} 