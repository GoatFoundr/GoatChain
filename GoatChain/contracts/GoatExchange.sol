// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GoatExchange is ReentrancyGuard, Ownable, Pausable {
    struct TokenInfo {
        bool isListed;
        uint256 minLiquidity;
        uint256 tradingFee; // in basis points
        address artist;
        string metadata; // IPFS hash for token metadata
        bool isPartnered; // Only partnered artists can list
    }
    
    struct Order {
        address seller;
        uint256 amount;
        uint256 price;
        bool isActive;
        uint256 timestamp;
    }
    
    // Platform fee settings
    uint256 public platformFee = 200; // 2% platform fee
    uint256 public artistFee = 100;   // 1% artist fee
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_PLATFORM_FEE = 400; // 4% max
    uint256 public constant MAX_ARTIST_FEE = 200;   // 2% max
    
    mapping(address => TokenInfo) public tokenInfo;
    mapping(address => mapping(address => Order)) public orders; // token => buyer => order
    mapping(address => uint256) public liquidity; // token => amount
    mapping(address => bool) public isPartneredArtist;
    
    event TokenListed(address indexed token, address indexed artist, uint256 minLiquidity);
    event OrderPlaced(address indexed token, address indexed buyer, uint256 amount, uint256 price);
    event OrderFilled(address indexed token, address indexed buyer, uint256 amount, uint256 price);
    event LiquidityAdded(address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed token, uint256 amount);
    event ArtistPartnered(address indexed artist);
    
    constructor() Ownable(msg.sender) {}
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function addPartneredArtist(address _artist) external onlyOwner {
        require(!isPartneredArtist[_artist], "Already partnered");
        isPartneredArtist[_artist] = true;
        emit ArtistPartnered(_artist);
    }
    
    function listToken(
        address _token,
        uint256 _minLiquidity,
        uint256 _tradingFee,
        string memory _metadata
    ) external whenNotPaused {
        require(isPartneredArtist[msg.sender], "Not a partnered artist");
        require(!tokenInfo[_token].isListed, "Token already listed");
        require(_tradingFee <= MAX_ARTIST_FEE, "Trading fee too high");
        
        tokenInfo[_token] = TokenInfo({
            isListed: true,
            minLiquidity: _minLiquidity,
            tradingFee: _tradingFee,
            artist: msg.sender,
            metadata: _metadata,
            isPartnered: true
        });
        
        emit TokenListed(_token, msg.sender, _minLiquidity);
    }
    
    function addLiquidity(address _token, uint256 _amount) external nonReentrant whenNotPaused {
        require(tokenInfo[_token].isListed, "Token not listed");
        
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        liquidity[_token] += _amount;
        
        emit LiquidityAdded(_token, _amount);
    }
    
    function removeLiquidity(address _token, uint256 _amount) external nonReentrant whenNotPaused {
        require(liquidity[_token] >= _amount, "Insufficient liquidity");
        
        liquidity[_token] -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        
        emit LiquidityRemoved(_token, _amount);
    }
    
    function placeOrder(
        address _token,
        uint256 _amount,
        uint256 _price
    ) external nonReentrant whenNotPaused {
        require(tokenInfo[_token].isListed, "Token not listed");
        require(_amount > 0 && _price > 0, "Invalid order");
        
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        
        orders[_token][msg.sender] = Order({
            seller: msg.sender,
            amount: _amount,
            price: _price,
            isActive: true,
            timestamp: block.timestamp
        });
        
        emit OrderPlaced(_token, msg.sender, _amount, _price);
    }
    
    function fillOrder(
        address _token,
        address _seller
    ) external payable nonReentrant whenNotPaused {
        Order storage order = orders[_token][_seller];
        require(order.isActive, "Order not active");
        require(msg.value >= order.price, "Insufficient payment");
        require(block.timestamp <= order.timestamp + 7 days, "Order expired");
        
        // Calculate fees
        uint256 platformFeeAmount = (order.price * platformFee) / BASIS_POINTS;
        uint256 artistFeeAmount = (order.price * tokenInfo[_token].tradingFee) / BASIS_POINTS;
        uint256 sellerAmount = order.price - platformFeeAmount - artistFeeAmount;
        
        // Transfer tokens to buyer
        IERC20(_token).transfer(msg.sender, order.amount);
        
        // Transfer payment to seller
        payable(_seller).transfer(sellerAmount);
        
        // Transfer fees
        payable(owner()).transfer(platformFeeAmount);
        payable(tokenInfo[_token].artist).transfer(artistFeeAmount);
        
        // Update order
        order.isActive = false;
        
        emit OrderFilled(_token, _seller, order.amount, order.price);
    }
    
    function cancelOrder(address _token) external nonReentrant whenNotPaused {
        Order storage order = orders[_token][msg.sender];
        require(order.isActive, "No active order");
        
        IERC20(_token).transfer(msg.sender, order.amount);
        order.isActive = false;
    }
    
    function updateTokenMetadata(address _token, string memory _metadata) external {
        require(msg.sender == tokenInfo[_token].artist, "Not authorized");
        tokenInfo[_token].metadata = _metadata;
    }
    
    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_PLATFORM_FEE, "Fee too high");
        platformFee = _fee;
    }
    
    function setArtistFee(address _token, uint256 _fee) external {
        require(msg.sender == tokenInfo[_token].artist, "Not authorized");
        require(_fee <= MAX_ARTIST_FEE, "Fee too high");
        tokenInfo[_token].tradingFee = _fee;
    }
    
    // Emergency functions
    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), balance);
    }
    
    function emergencyPause() external onlyOwner {
        _pause();
    }
} 