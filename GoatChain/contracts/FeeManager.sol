// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FeeManager is Ownable, ReentrancyGuard {
    // Fee percentages (in basis points, 100 = 1%)
    uint256 public constant GOATCHAIN_PLATFORM_FEE = 200; // 2%
    uint256 public constant GOATCHAIN_REWARDS_FEE = 100; // 1%
    uint256 public constant ARTIST_PLATFORM_FEE = 100; // 1%
    uint256 public constant ARTIST_ARTIST_FEE = 100; // 1%
    uint256 public constant ARTIST_REWARDS_FEE = 100; // 1%

    // Fee recipients
    address public platformWallet;
    address public rewardsPool;
    mapping(address => address) public artistWallets; // token => artist wallet

    event FeesCollected(
        address indexed token,
        uint256 platformFee,
        uint256 artistFee,
        uint256 rewardsFee
    );

    constructor(address _platformWallet, address _rewardsPool) {
        platformWallet = _platformWallet;
        rewardsPool = _rewardsPool;
    }

    function setArtistWallet(address token, address wallet) external onlyOwner {
        artistWallets[token] = wallet;
    }

    function updatePlatformWallet(address _platformWallet) external onlyOwner {
        platformWallet = _platformWallet;
    }

    function updateRewardsPool(address _rewardsPool) external onlyOwner {
        rewardsPool = _rewardsPool;
    }

    function collectFees(
        address token,
        uint256 amount,
        bool isGoatChain
    ) external nonReentrant returns (uint256 platformFee, uint256 artistFee, uint256 rewardsFee) {
        IERC20 tokenContract = IERC20(token);

        if (isGoatChain) {
            // GOATCHAIN token fees (2% platform, 1% rewards)
            platformFee = (amount * GOATCHAIN_PLATFORM_FEE) / 10000;
            rewardsFee = (amount * GOATCHAIN_REWARDS_FEE) / 10000;
            artistFee = 0;

            // Transfer fees
            if (platformFee > 0) {
                require(
                    tokenContract.transfer(platformWallet, platformFee),
                    "Platform fee transfer failed"
                );
            }
            if (rewardsFee > 0) {
                require(
                    tokenContract.transfer(rewardsPool, rewardsFee),
                    "Rewards fee transfer failed"
                );
            }
        } else {
            // Artist token fees (1% platform, 1% artist, 1% rewards)
            platformFee = (amount * ARTIST_PLATFORM_FEE) / 10000;
            artistFee = (amount * ARTIST_ARTIST_FEE) / 10000;
            rewardsFee = (amount * ARTIST_REWARDS_FEE) / 10000;

            // Transfer fees
            if (platformFee > 0) {
                require(
                    tokenContract.transfer(platformWallet, platformFee),
                    "Platform fee transfer failed"
                );
            }
            if (artistFee > 0) {
                require(
                    tokenContract.transfer(artistWallets[token], artistFee),
                    "Artist fee transfer failed"
                );
            }
            if (rewardsFee > 0) {
                require(
                    tokenContract.transfer(rewardsPool, rewardsFee),
                    "Rewards fee transfer failed"
                );
            }
        }

        emit FeesCollected(token, platformFee, artistFee, rewardsFee);
    }

    function calculateFees(uint256 amount, bool isGoatChain)
        external
        pure
        returns (uint256 platformFee, uint256 artistFee, uint256 rewardsFee)
    {
        if (isGoatChain) {
            platformFee = (amount * GOATCHAIN_PLATFORM_FEE) / 10000;
            rewardsFee = (amount * GOATCHAIN_REWARDS_FEE) / 10000;
            artistFee = 0;
        } else {
            platformFee = (amount * ARTIST_PLATFORM_FEE) / 10000;
            artistFee = (amount * ARTIST_ARTIST_FEE) / 10000;
            rewardsFee = (amount * ARTIST_REWARDS_FEE) / 10000;
        }
    }
} 