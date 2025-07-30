// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../contracts/Subscription.sol";
import "../contracts/mocks/USDCMock.sol";
import "../contracts/mocks/RWAManagerMock.sol";

contract SubscriptionTest is Test {
    error StartTimeMustBeLaterThanCurrentTime();
    error StartTimeMustBeLessThanEndTime();
    error SubscriptionAlreadyStarted();

    Subscription public subscription;
    RWAToken public rwaToken;
    RWAManagerMock public rwaManager;
    USDCMock public usdc;

    address public owner = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);

    uint256 public period = 1;
    uint256 public startTime = block.timestamp + 1 days;
    uint256 public endTime = startTime + 7 days;
    uint256 public totalCap = 1000 * 1e6; // 1000 USDC (6 decimals)
    uint256 public userCap = 100 * 1e6;   // 100 USDC (6 decimals)

    function setUp() public {
        // Deploy mock USDC token
        usdc = new USDCMock(1000000 * 1e6); // 1M USDC (6 decimals)

        // Deploy RWAToken
        vm.prank(owner);
        rwaToken = new RWAToken("RWA Token", "RWA");

        // Deploy RWAManagerMock contract
        vm.prank(owner);
        rwaManager = new RWAManagerMock(address(rwaToken), address(usdc));

        // Set RWAManager as RWAToken's manager
        vm.prank(owner);
        rwaToken.setManager(address(rwaManager));

        // Deploy Subscription contract
        vm.prank(owner);
        subscription = new Subscription(startTime, endTime, totalCap, userCap, owner, address(rwaManager));

        // Register the Subscription contract with RWAManager for the specified period
        vm.prank(owner);
        rwaManager.createSubscriptionContract(period, startTime, endTime, totalCap, userCap);

        // Mint USDC to Alice and Bob for testing
        usdc.mint(alice, 1000 * 1e6); // 1000 USDC (6 decimals)
        usdc.mint(bob, 1000 * 1e6);   // 1000 USDC (6 decimals)
    }

    // ========== Helper Functions ==========

    function _warpToActivePeriod() internal {
        vm.warp(startTime + 1); // Warp to just after the start time
    }

    function _warpToAfterEndTime() internal {
        vm.warp(endTime + 1); // Warp to just after the end time
    }

    // ========== Test for Subscription Constructor ==========

    function testSubscriptionConstructor() public {
        // === Test 1: Constructor initializes correctly ===
        // Check the subscription period start and end times
        assertEq(subscription.startTime(), startTime, "Start time incorrect");
        assertEq(subscription.endTime(), endTime, "End time incorrect");

        // Check the total and user caps
        assertEq(subscription.totalCap(), totalCap, "Total cap incorrect");
        assertEq(subscription.userCap(), userCap, "User cap incorrect");

        // Check the manager address
        assertEq(subscription.manager(), address(rwaManager), "Manager address incorrect");

        // === Test 2: Constructor reverts if start time is in the past ===
        vm.warp(3 days);
        uint256 pastStartTime = block.timestamp - 1 days;
        vm.expectRevert(StartTimeMustBeLaterThanCurrentTime.selector);
        new Subscription(pastStartTime, endTime, totalCap, userCap, owner, address(rwaManager));

        // === Test 3: Constructor reverts if start time is greater than or equal to end time ===
        startTime = block.timestamp + 1 days;
        uint256 invalidEndTime = startTime - 1 days;
        vm.expectRevert(StartTimeMustBeLessThanEndTime.selector);
        new Subscription(startTime, invalidEndTime, totalCap, userCap, owner, address(rwaManager));
    }

    // ========== Tests for Subscription ==========

    function testSubscriptionContractCreation() public {
        assertTrue(address(subscription) != address(0), "Subscription contract not created");
    }

    function testSetExchangeRate() public {
        uint256 newRate = 1.5 ether; // 1 USDC = 1.5 RWA

        vm.prank(owner);
        subscription.setExchangeRate(newRate);

        assertEq(subscription.rate(), newRate, "Exchange rate not updated");
    }

    function testSetClaimable() public {
        vm.prank(owner);
        subscription.setClaimable(true);

        assertTrue(subscription.claimable(), "Claimable status not updated");
    }

    function testAddUserUSDCBalance() public {
        // Warp to the active subscription period
        _warpToActivePeriod();

        // Alice subscribes with 50 USDC
        vm.prank(address(rwaManager));
        subscription.addUserUSDCBalance(alice, 50 * 1e6);

        // Check Alice's USDC balance in the subscription contract
        uint256 aliceBalance = subscription.userUSDCBalance(alice);
        assertEq(aliceBalance, 50 * 1e6, "Alice's USDC balance incorrect");
    }

    function testResetUserUSDCBalance() public {
        // Warp to the active subscription period
        _warpToActivePeriod();

        // Alice subscribes with 50 USDC
        vm.prank(address(rwaManager));
        subscription.addUserUSDCBalance(alice, 50 * 1e6);

        // Reset Alice's USDC balance
        vm.prank(address(rwaManager));
        subscription.resetUserUSDCBalance(alice);

        // Check Alice's USDC balance in the subscription contract
        uint256 aliceBalance = subscription.userUSDCBalance(alice);
        assertEq(aliceBalance, 0, "Alice's USDC balance not reset");
    }

    function testIsActive() public {
        // Before the subscription period starts
        vm.warp(startTime - 1);
        assertFalse(subscription.isActive(), "Subscription should not be active");

        // During the subscription period
        _warpToActivePeriod();
        assertTrue(subscription.isActive(), "Subscription should be active");

        // After the subscription period ends
        _warpToAfterEndTime();
        assertFalse(subscription.isActive(), "Subscription should not be active");
    }

    // ========== Tests for Admin Functions ==========

    function testSetSubscriptionTime() public {
        uint256 newStartTime = block.timestamp + 2 days;
        uint256 newEndTime = newStartTime + 7 days;

        // Ensure the function reverts if called after the subscription starts
        _warpToActivePeriod(); // After subscription starts
        vm.prank(owner);
        vm.expectRevert(SubscriptionAlreadyStarted.selector);
        subscription.setSubscriptionTime(newStartTime, newEndTime);

        // Ensure the function can only be called before the subscription starts
        vm.warp(startTime - 1); // Before subscription starts
        vm.prank(owner);
        subscription.setSubscriptionTime(newStartTime, newEndTime);

        // Check that the subscription time was updated
        assertEq(subscription.startTime(), newStartTime, "Start time not updated");
        assertEq(subscription.endTime(), newEndTime, "End time not updated");
    }

    function testSetCaps() public {
        uint256 newTotalCap = 2000 * 1e6; // 2000 USDC (6 decimals)
        uint256 newUserCap = 200 * 1e6;   // 200 USDC (6 decimals)

        // Ensure the function can only be called before the subscription starts
        vm.warp(startTime - 1); // Before subscription starts
        vm.prank(owner);
        subscription.setCaps(newTotalCap, newUserCap);

        // Check that the caps were updated
        assertEq(subscription.totalCap(), newTotalCap, "Total cap not updated");
        assertEq(subscription.userCap(), newUserCap, "User cap not updated");

        // Ensure the function reverts if called after the subscription starts
        _warpToActivePeriod(); // After subscription starts
        vm.prank(owner);
        vm.expectRevert(SubscriptionAlreadyStarted.selector);
        subscription.setCaps(newTotalCap, newUserCap);
    }
}