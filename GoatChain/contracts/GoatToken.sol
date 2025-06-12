// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title GoatToken (GOATCHAIN)
/// @notice Native utility token for the GoatChain ecosystem.
contract GoatToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @notice Maximum supply = 1,000,000,000 * 10 ** decimals()
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    /// @notice Once-only initializer instead of constructor.
    /// @param _treasury Address receiving the full initial supply.
    function initialize(address _treasury) external initializer {
        require(_treasury != address(0), "treasury!=0");
        __ERC20_init("GOATCHAIN", "GOATCHAIN");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _mint(_treasury, MAX_SUPPLY);
    }

    /// @dev Required by UUPS for upgrade authorization.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 