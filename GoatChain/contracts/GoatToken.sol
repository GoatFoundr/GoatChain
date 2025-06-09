// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GoatToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    // Fee settings
    uint256 public platformFee = 200; // 2% platform fee
    uint256 public liquidityFee = 100; // 1% liquidity fee
    uint256 public constant BASIS_POINTS = 10000;
    
    address public platformFeeCollector;
    address public liquidityPool;
    
    event PlatformFeeCollected(address indexed from, uint256 amount);
    event LiquidityFeeCollected(address indexed from, uint256 amount);
    
    // Tokenomics
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    uint256 public constant STAKING_REWARDS = 200_000_000 * 10**18; // 200 million tokens
    uint256 public constant ECOSYSTEM_FUND = 300_000_000 * 10**18; // 300 million tokens
    uint256 public constant TEAM_TOKENS = 100_000_000 * 10**18; // 100 million tokens
    uint256 public constant MARKETING = 100_000_000 * 10**18; // 100 million tokens
    uint256 public constant COMMUNITY_REWARDS = 200_000_000 * 10**18; // 200 million tokens

    // Vesting
    uint256 public constant VESTING_PERIOD = 365 days;
    uint256 public constant VESTING_CLIFF = 180 days;
    uint256 public startTime;
    mapping(address => uint256) public vestedAmount;
    mapping(address => uint256) public claimedAmount;

    // Events
    event TokensVested(address indexed beneficiary, uint256 amount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event StakingRewardsUpdated(uint256 amount);
    event EcosystemFundUpdated(uint256 amount);
    event TeamTokensUpdated(uint256 amount);
    event MarketingUpdated(uint256 amount);
    event CommunityRewardsUpdated(uint256 amount);
    
    constructor() ERC20("GoatChain", "GOATCHAIN") Ownable(msg.sender) {
        platformFeeCollector = msg.sender;
        startTime = block.timestamp;
        _mint(address(this), INITIAL_SUPPLY);
        _mint(address(this), STAKING_REWARDS);
        _mint(address(this), ECOSYSTEM_FUND);
        _mint(address(this), TEAM_TOKENS);
        _mint(address(this), MARKETING);
        _mint(address(this), COMMUNITY_REWARDS);
    }
    
    function setPlatformFeeCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid address");
        platformFeeCollector = _collector;
    }
    
    function setLiquidityPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPool = _pool;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (sender == owner() || recipient == owner() || sender == platformFeeCollector || recipient == platformFeeCollector) {
            super._transfer(sender, recipient, amount);
            return;
        }
        
        // Calculate fees
        uint256 platformFeeAmount = (amount * platformFee) / BASIS_POINTS;
        uint256 liquidityFeeAmount = (amount * liquidityFee) / BASIS_POINTS;
        uint256 transferAmount = amount - platformFeeAmount - liquidityFeeAmount;
        
        // Transfer main amount
        super._transfer(sender, recipient, transferAmount);
        
        // Transfer platform fee
        super._transfer(sender, platformFeeCollector, platformFeeAmount);
        emit PlatformFeeCollected(sender, platformFeeAmount);
        
        // Transfer liquidity fee
        super._transfer(sender, liquidityPool, liquidityFeeAmount);
        emit LiquidityFeeCollected(sender, liquidityFeeAmount);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
} 