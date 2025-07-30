// contracts/USDCMock.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20 {
    constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") {
        _mint(msg.sender, initialSupply); // Mint initial supply to the deployer
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // Function to mint new tokens for testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // Function to burn tokens for testing
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function test() external {}
}