// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LazerDimToken is ERC20, Ownable, Pausable {
    event TokensBurned(address indexed burner, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);

    constructor() ERC20("LazerDim700", "LD700") {
        // Mint initial supply to the contract deployer
        _mint(msg.sender, 700000000 * 10 ** decimals()); // 700 million tokens
    }

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
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