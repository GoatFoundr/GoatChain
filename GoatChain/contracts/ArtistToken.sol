// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ArtistToken is ERC20, Ownable, Pausable {
    string public artistName;
    address public artistAddress;
    uint256 public constant MAX_SUPPLY = 1000000000 * 10 ** 18; // 1 billion tokens
    bool public rewardsEnabled;
    
    event RewardsEnabled(address indexed artist);
    event RewardsDisabled(address indexed artist);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _artistName,
        address _artistAddress
    ) ERC20(_name, _symbol) {
        artistName = _artistName;
        artistAddress = _artistAddress;
        _mint(_artistAddress, MAX_SUPPLY / 2); // 50% to artist
        _mint(owner(), MAX_SUPPLY / 2); // 50% to platform for staking rewards
    }

    function enableRewards() external onlyOwner {
        require(!rewardsEnabled, "Rewards already enabled");
        rewardsEnabled = true;
        emit RewardsEnabled(artistAddress);
    }

    function disableRewards() external onlyOwner {
        require(rewardsEnabled, "Rewards already disabled");
        rewardsEnabled = false;
        emit RewardsDisabled(artistAddress);
    }

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
} 