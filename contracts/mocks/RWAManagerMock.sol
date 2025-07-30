// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../contracts/RWAManager.sol";

contract RWAManagerMock is RWAManager {
    constructor(address rwa,address usdc) RWAManager(rwa, usdc) {}

    // Add a mint function for testing purposes
    function mint(address to, uint256 amount) external {
        RWA_TOKEN.mintByManager(to, amount);
    }

    function test() external {}
}