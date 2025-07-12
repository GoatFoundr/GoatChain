// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./FeeManager.sol";

contract GoatChainToken is ERC20, Ownable, Pausable {
    FeeManager public feeManager;

    event TokensBurned(address indexed burner, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);

    constructor(address _feeManager) ERC20("GoatChain", "GOATCHAIN") {
        feeManager = FeeManager(_feeManager);
        _mint(msg.sender, 1000000000 * 10 ** decimals()); // 1 billion tokens
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        if (from == address(0) || to == address(0) || from == owner() || to == feeManager.platformWallet() || to == feeManager.rewardsWallet()) {
            super._transfer(from, to, amount);
            return;
        }

        (uint256 platformFee, uint256 rewardsFee) = feeManager.getGoatChainFees(amount);
        uint256 totalFees = platformFee + rewardsFee;
        uint256 sendAmount = amount - totalFees;

        require(amount >= totalFees, "Amount too small for fees");

        super._transfer(from, feeManager.platformWallet(), platformFee);
        super._transfer(from, feeManager.rewardsWallet(), rewardsFee);
        super._transfer(from, to, sendAmount);
    }
    
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = FeeManager(_feeManager);
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
 