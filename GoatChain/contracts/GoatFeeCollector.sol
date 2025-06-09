// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GoatFeeCollector is Ownable, ReentrancyGuard {
    struct FeeBalance {
        uint256 platformFees;
        uint256 lastClaimTime;
    }
    
    // Platform fee wallet
    address public platformWallet;
    
    // Fee balances for each token
    mapping(address => FeeBalance) public feeBalances;
    
    event FeesCollected(address indexed token, uint256 amount);
    event PlatformWalletUpdated(address indexed newWallet);
    
    constructor() Ownable(msg.sender) {
        platformWallet = msg.sender;
    }
    
    function setPlatformWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid wallet");
        platformWallet = _wallet;
        emit PlatformWalletUpdated(_wallet);
    }
    
    function collectFees(address _token) external nonReentrant {
        FeeBalance storage balance = feeBalances[_token];
        require(balance.platformFees > 0, "No fees to collect");
        
        uint256 amount = balance.platformFees;
        balance.platformFees = 0;
        balance.lastClaimTime = block.timestamp;
        
        IERC20(_token).transfer(platformWallet, amount);
        
        emit FeesCollected(_token, amount);
    }
    
    function addFees(address _token, uint256 _amount) external {
        require(msg.sender == owner(), "Not authorized");
        feeBalances[_token].platformFees += _amount;
    }
    
    function getFeeBalance(address _token) external view returns (uint256) {
        return feeBalances[_token].platformFees;
    }
    
    function getLastClaimTime(address _token) external view returns (uint256) {
        return feeBalances[_token].lastClaimTime;
    }
    
    // Emergency functions
    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(platformWallet, balance);
    }
} 