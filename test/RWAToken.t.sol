// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../contracts/RWAToken.sol";
import "../contracts/RWAManager.sol";
import "../contracts/Subscription.sol";
import "../contracts/Redemption.sol";
import "../contracts/mocks/USDCMock.sol";

contract RWATokenTest is Test {
    error InvalidWhale();
    error InvalidManager();

    RWAToken public rwaToken;

    address public owner = address(0x1);
    address public manager = address(0x2);

    function setUp() public {
        vm.prank(owner);
        rwaToken = new RWAToken("RWA Token", "RWA");
    }

    function testMintAndBurnForWhale() public {
        address whale = address(0x123);

        vm.startPrank(owner);
        vm.expectRevert(InvalidWhale.selector);
        rwaToken.mintForWhale(whale, 1 ether);

        rwaToken.setWhaleList(whale, true);
        rwaToken.mintForWhale(whale, 1 ether);
        assertEq(rwaToken.balanceOf(whale), 1 ether);

        rwaToken.burnForWhale(whale, 1 ether);
        assertEq(rwaToken.balanceOf(whale), 0);

        rwaToken.setWhaleList(whale, false);
        vm.expectRevert(InvalidWhale.selector);
        rwaToken.mintForWhale(whale, 1 ether);

        vm.expectRevert(InvalidWhale.selector);
        rwaToken.burnForWhale(owner, 1 ether);
        assertEq(rwaToken.balanceOf(whale), 0);
    }

    function testMintOrBurnByNonManager() public {
        vm.startPrank(owner);

        vm.expectRevert(InvalidManager.selector);
        rwaToken.mintByManager(owner, 1);

        vm.expectRevert(InvalidManager.selector);
        rwaToken.burnByManager(owner, 1);
    }
}
