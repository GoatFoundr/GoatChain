// OpenZeppelin 5.x uses _update hook instead of _beforeTokenTransfer
function _update(
    address from,
    address to,
    uint256 value
) internal override {
    if (from == owner() && block.timestamp < lockUntil) {
        revert("Artist tokens locked");
    }
    super._update(from, to, value);
} 