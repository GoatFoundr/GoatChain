// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title FeeManager
/// @notice Centralised contract for routing fees on GoatChain.
contract FeeManager is OwnableUpgradeable, UUPSUpgradeable {
    // Fees expressed in basis points (1% = 100, 100% = 10_000)
    uint256 public constant MAX_BPS = 10_000;

    // Artist token fee defaults
    uint256 public constant ARTIST_PLATFORM_FEE_BPS = 100; // 1%
    uint256 public constant ARTIST_ROYALTY_FEE_BPS = 100;  // 1%
    uint256 public constant ARTIST_FAN_FEE_BPS = 100;      // 1%

    // GOATCHAIN token fee defaults
    uint256 public constant GOAT_PLATFORM_FEE_BPS = 200; // 2%
    uint256 public constant GOAT_REWARD_FEE_BPS = 100;   // 1%

    // Addresses
    address public platformTreasury;
    address public fanRewardsPool;

    // artist address => royalty receiver (usually same as artist)
    mapping(address => address) public artistRoyaltyReceiver;

    event PlatformTreasuryUpdated(address indexed newTreasury);
    event FanRewardsPoolUpdated(address indexed newRewardsPool);
    event ArtistRoyaltyReceiverUpdated(address indexed artist, address indexed receiver);

    event ArtistTokenFeesRouted(address indexed artistToken, uint256 amount, uint256 toPlatform, uint256 toArtist, uint256 toFans);
    event GoatTokenFeesRouted(uint256 amount, uint256 toPlatform, uint256 toRewardsPool);

    function initialize(address _platformTreasury, address _fanRewardsPool) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        require(_platformTreasury != address(0) && _fanRewardsPool != address(0), "addr!=0");
        platformTreasury = _platformTreasury;
        fanRewardsPool = _fanRewardsPool;
    }

    // ================== Admin Setters ==================

    function setPlatformTreasury(address _platformTreasury) external onlyOwner {
        require(_platformTreasury != address(0), "addr!=0");
        platformTreasury = _platformTreasury;
        emit PlatformTreasuryUpdated(_platformTreasury);
    }

    function setFanRewardsPool(address _fanRewardsPool) external onlyOwner {
        require(_fanRewardsPool != address(0), "addr!=0");
        fanRewardsPool = _fanRewardsPool;
        emit FanRewardsPoolUpdated(_fanRewardsPool);
    }

    function setArtistRoyaltyReceiver(address _artist, address _receiver) external onlyOwner {
        require(_receiver != address(0) && _artist != address(0), "addr!=0");
        artistRoyaltyReceiver[_artist] = _receiver;
        emit ArtistRoyaltyReceiverUpdated(_artist, _receiver);
    }

    // ================== Fee Routing ==================

    /// @notice Handle fees for an artist token transfer. The calling contract should have already
    ///         transferred `feeAmount` to this contract before calling.
    function routeArtistTokenFees(address artistToken, uint256 feeAmount) external {
        require(feeAmount > 0, "fee=0");
        IERC20Upgradeable token = IERC20Upgradeable(artistToken);

        uint256 toPlatform = (feeAmount * ARTIST_PLATFORM_FEE_BPS) / MAX_BPS;
        uint256 toFans = (feeAmount * ARTIST_FAN_FEE_BPS) / MAX_BPS;
        uint256 toArtist = feeAmount - toPlatform - toFans; // 1% each so remainder 1%

        address artistReceiver = artistRoyaltyReceiver[artistToken];
        if (artistReceiver == address(0)) artistReceiver = owner();

        if (toPlatform > 0) token.transfer(platformTreasury, toPlatform);
        if (toFans > 0) token.transfer(fanRewardsPool, toFans);
        if (toArtist > 0) token.transfer(artistReceiver, toArtist);

        emit ArtistTokenFeesRouted(artistToken, feeAmount, toPlatform, toArtist, toFans);
    }

    /// @notice Handle GOATCHAIN token fees (assumes tokens transferred in advance)
    function routeGoatTokenFees(address goatTokenAddress, uint256 feeAmount) external {
        require(feeAmount > 0, "fee=0");
        IERC20Upgradeable token = IERC20Upgradeable(goatTokenAddress);

        uint256 toPlatform = (feeAmount * GOAT_PLATFORM_FEE_BPS) / MAX_BPS;
        uint256 toRewards = (feeAmount * GOAT_REWARD_FEE_BPS) / MAX_BPS;
        uint256 remainder = feeAmount - toPlatform - toRewards;

        if (toPlatform > 0) token.transfer(platformTreasury, toPlatform);
        if (toRewards > 0) token.transfer(fanRewardsPool, toRewards);
        if (remainder > 0) token.transfer(platformTreasury, remainder); // safety send remainder to platform

        emit GoatTokenFeesRouted(feeAmount, toPlatform, toRewards);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 