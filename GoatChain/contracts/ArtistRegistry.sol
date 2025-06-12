// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./ArtistToken.sol";

/// @title ArtistRegistry
/// @notice GoatFundr-admin contract to deploy artist ERC20 tokens and keep registry.
contract ArtistRegistry is OwnableUpgradeable, UUPSUpgradeable {
    // Address of ArtistToken implementation used for proxies
    address public artistTokenImplementation;

    // Mapping artist wallet => artist token address
    mapping(address => address) public artistTokens;

    // Array of all deployed artist tokens
    address[] public allArtistTokens;

    event ArtistTokenImplementationUpdated(address indexed newImplementation);
    event ArtistRegistered(address indexed artist, address indexed token, string name, string symbol);

    function initialize(address _artistTokenImplementation) external initializer {
        require(_artistTokenImplementation != address(0), "impl!=0");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        artistTokenImplementation = _artistTokenImplementation;
    }

    /// @notice Update implementation logic for new deployments.
    function setArtistTokenImplementation(address _implementation) external onlyOwner {
        require(_implementation != address(0), "impl!=0");
        artistTokenImplementation = _implementation;
        emit ArtistTokenImplementationUpdated(_implementation);
    }

    /// @notice Deploy an ArtistToken for a new artist.
    /// @param _name Token name
    /// @param _symbol Token symbol
    /// @param _artist Artist wallet (owner)
    /// @param _initialSupply Initial supply minted to artist wallet
    function registerArtist(
        string memory _name,
        string memory _symbol,
        address _artist,
        uint256 _initialSupply
    ) external onlyOwner returns (address tokenAddress) {
        require(artistTokens[_artist] == address(0), "already registered");
        bytes memory initData = abi.encodeWithSelector(
            ArtistToken.initialize.selector,
            _name,
            _symbol,
            _artist,
            _initialSupply,
            365 days
        );
        ERC1967Proxy proxy = new ERC1967Proxy(artistTokenImplementation, initData);
        tokenAddress = address(proxy);
        artistTokens[_artist] = tokenAddress;
        allArtistTokens.push(tokenAddress);

        emit ArtistRegistered(_artist, tokenAddress, _name, _symbol);
    }

    function getAllArtistTokens() external view returns (address[] memory) {
        return allArtistTokens;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 