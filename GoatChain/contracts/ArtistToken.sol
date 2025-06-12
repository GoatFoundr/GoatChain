// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title ArtistToken
/// @notice ERC20 token template for artists launched via GoatFundr.
contract ArtistToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // Timestamp until which the artist (owner) cannot transfer their own tokens
    uint256 public lockUntil;

    event ArtistTransferLocked(address indexed artist, uint256 untilTimestamp);

    /// @notice Initializer to be called by ArtistRegistry when deploying a new token.
    /// @param _name Token name ("ArtistName Token")
    /// @param _symbol ERC20 symbol
    /// @param _artist Address of the artist wallet which becomes owner and initial holder
    /// @param _initialSupply Initial supply minted to artist
    /// @param _lockDuration Lock duration in seconds (e.g. 365 days)
    function initialize(
        string memory _name,
        string memory _symbol,
        address _artist,
        uint256 _initialSupply,
        uint256 _lockDuration
    ) external initializer {
        require(_artist != address(0), "artist!=0");
        __ERC20_init(_name, _symbol);
        __Ownable_init(_artist);
        __UUPSUpgradeable_init();

        _mint(_artist, _initialSupply);
        lockUntil = block.timestamp + _lockDuration;

        emit ArtistTransferLocked(_artist, lockUntil);
    }

    /// @dev Reverts if artist tries to transfer within lock period
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == owner() && block.timestamp < lockUntil) {
            revert("Artist tokens locked");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev Upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 