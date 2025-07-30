// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../contracts/Redemption.sol";
import "../contracts/mocks/USDCMock.sol";
import "../contracts/mocks/RWAManagerMock.sol";

contract RedemptionTest is Test {
    error StartTimeMustBeLaterThanCurrentTime();
    error StartTimeMustBeLessThanEndTime();

    Redemption public redemption;
    RWAToken public rwaToken;
    RWAManagerMock public rwaManager;
    USDCMock public usdc;

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    uint256 public period = 1;
    uint256 public startTime = block.timestamp + 1 days;
    uint256 public endTime = startTime + 7 days;
    uint256 public totalCap = 1000 * 1e18; // 1000 RWA (18 decimals)
    uint256 public userCap = 100 * 1e18;   // 100 RWA (18 decimals)

    function setUp() public {
        // Deploy mock USDC token
        usdc = new USDCMock(1000000 * 1e6); // 1M USDC (6 decimals)

        // Deploy RWAToken
        vm.prank(owner);
        rwaToken = new RWAToken("RWA Token", "RWA");

        // Deploy RWAManager contract
        vm.prank(owner);
        rwaManager = new RWAManagerMock(address(rwaToken), address(usdc));

        // Set RWAManager as RWAToken's manager
        vm.prank(owner);
        rwaToken.setManager(address(rwaManager));

        // Deploy Redemption contract
        vm.prank(owner);
        redemption = new Redemption(startTime, endTime, totalCap, userCap, owner, address(rwaManager));

        // Mint RWA tokens to Alice and Bob for testing
        vm.prank(owner);
        rwaManager.mint(alice, 1000 * 1e18); // 1000 RWA (18 decimals)
        vm.prank(owner);
        rwaManager.mint(bob, 1000 * 1e18);   // 1000 RWA (18 decimals)
    }

    // ========== Helper Functions ==========

    function _warpToActivePeriod() internal {
        vm.warp(startTime + 1); // Warp to just after the start time
    }

    function _warpToAfterEndTime() internal {
        vm.warp(endTime + 1); // Warp to just after the end time
    }

    // ========== Test for Redemption Constructor ==========

    function testSubscriptionConstructor() public {
        // === Test 1: Constructor initializes correctly ===
        // Check the redemption period start and end times
        assertEq(redemption.startTime(), startTime, "Start time incorrect");
        assertEq(redemption.endTime(), endTime, "End time incorrect");

        // Check the total and user caps
        assertEq(redemption.totalCap(), totalCap, "Total cap incorrect");
        assertEq(redemption.userCap(), userCap, "User cap incorrect");

        // Check the manager address
        assertEq(redemption.manager(), address(rwaManager), "Manager address incorrect");

        // === Test 2: Constructor reverts if start time is in the past ===
        vm.warp(3 days);
        uint256 pastStartTime = block.timestamp - 1 days;
        vm.expectRevert(StartTimeMustBeLaterThanCurrentTime.selector);
        new Redemption(pastStartTime, endTime, totalCap, userCap, owner, address(rwaManager));

        // === Test 3: Constructor reverts if start time is greater than or equal to end time ===
        startTime = block.timestamp + 1 days;
        uint256 invalidEndTime = startTime - 1 days;
        vm.expectRevert(StartTimeMustBeLessThanEndTime.selector);
        new Redemption(startTime, invalidEndTime, totalCap, userCap, owner, address(rwaManager));
    }

    // ========== Tests for Redemption ==========

    function testRedemptionContractCreation() public {
        assertTrue(address(redemption) != address(0), "Redemption contract not created");
    }

    function testSetRedemptionTime() public {
        uint256 newStartTime = block.timestamp + 3 days;
        uint256 newEndTime = block.timestamp + 4 days;

        vm.prank(owner);
        redemption.setRedemptionTime(newStartTime, newEndTime);

        assertEq(redemption.startTime(), newStartTime, "Start time not updated");
        assertEq(redemption.endTime(), newEndTime, "End time not updated");
    }

    function testSetCaps() public {
        uint256 newTotalCap = 2000 * 1e18; // 2000 RWA (18 decimals)
        uint256 newUserCap = 200 * 1e18; // 200 RWA (18 decimals)

        vm.prank(owner);
        redemption.setCaps(newTotalCap, newUserCap);

        assertEq(redemption.totalCap(), newTotalCap, "Total cap not updated");
        assertEq(redemption.userCap(), newUserCap, "User cap not updated");
    }

    function testSetExchangeRate() public {
        uint256 newRate = 1.2 ether; // 1 RWA = 1.2 USDC

        vm.prank(owner);
        redemption.setExchangeRate(newRate);

        assertEq(redemption.rate(), newRate, "Exchange rate not updated");
    }

    function testSetClaimRatio() public {
        uint256 newClaimRatio = 500000; // 50%

        vm.prank(owner);
        redemption.setClaimRatio(newClaimRatio);

        assertEq(redemption.claimRatio(), newClaimRatio, "Claim ratio not updated");
    }

    function testSetClaimable() public {
        vm.prank(owner);
        redemption.setClaimable(true);

        assertTrue(redemption.claimable(), "Claimable status not updated");
    }

    function testAddUserRWABalance() public {
        // Warp to the active redemption period
        _warpToActivePeriod();

        // Alice redeems 50 RWA tokens
        vm.prank(address(rwaManager));
        redemption.addUserRWABalance(alice, 50 * 1e18);

        // Check Alice's RWA balance in the redemption contract
        uint256 aliceBalance = redemption.userRWABalance(alice);
        assertEq(aliceBalance, 50 * 1e18, "Alice's RWA balance incorrect");
    }

    function testResetUserRWABalance() public {
        // Warp to the active redemption period
        _warpToActivePeriod();

        // Alice redeems 50 RWA tokens
        vm.prank(address(rwaManager));
        redemption.addUserRWABalance(alice, 50 * 1e18);

        // Reset Alice's RWA balance
        vm.prank(address(rwaManager));
        redemption.resetUserRWABalance(alice);

        // Check Alice's RWA balance in the redemption contract
        uint256 aliceBalance = redemption.userRWABalance(alice);
        assertEq(aliceBalance, 0, "Alice's RWA balance not reset");
    }

    function testIsActive() public {
        // Before the redemption period starts
        vm.warp(startTime - 1);
        assertFalse(redemption.isActive(), "Redemption should not be active");

        // During the redemption period
        _warpToActivePeriod();
        assertTrue(redemption.isActive(), "Redemption should be active");

        // After the redemption period ends
        _warpToAfterEndTime();
        assertFalse(redemption.isActive(), "Redemption should not be active");
    }
}