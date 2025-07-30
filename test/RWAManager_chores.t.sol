// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {RWAManagerTest} from "./RWAManager.t.sol";

contract RWAManagerChoresTest is RWAManagerTest {

    error OnlyAdminCanCall();
    error SubscriptionContractAlreadyExists();
    error RedemptionContractAlreadyExists();
    error InvalidPeriod();
    error SubscriptionNotActive();
    
    function testOnlyAdmin() public {
        vm.expectRevert(OnlyAdminCanCall.selector);
        rwaManager.setMerkleRoot(root);
    }

    function testCreateSubscriptionAlreadyExist() public {
        vm.prank(owner);
        vm.expectRevert(SubscriptionContractAlreadyExists.selector);
        rwaManager.createSubscriptionContract(
            period,
            subscriptionStartTime,
            subscriptionEndTime,
            subscriptionTotalCap,
            subscriptionUserCap
        );
    }

    function testCreateRedemptionAlreadyExist() public {
        vm.prank(owner);
        vm.expectRevert(RedemptionContractAlreadyExists.selector);
        rwaManager.createRedemptionContract(
            period,
            redemptionStartTime,
            redemptionEndTime,
            redemptionTotalCap,
            redemptionUserCap
        );
    }

    function testSubscribeFail() public {
        vm.prank(alice);
        vm.expectRevert(InvalidPeriod.selector);
        rwaManager.subscribe(period + 1, 10, proofs[alice]);

        vm.prank(alice);
        vm.expectRevert(InvalidAmount.selector);
        rwaManager.subscribe(period, 0, proofs[alice]);

        vm.warp(subscriptionStartTime - 1);
        vm.prank(alice);
        vm.expectRevert(SubscriptionNotActive.selector);
        rwaManager.subscribe(period, 10, proofs[alice]);
    }

    function testCancelSubscribeFail() public {
        vm.prank(alice);
        vm.expectRevert(InvalidPeriod.selector);
        rwaManager.cancelSubscription(period + 1);

        vm.warp(subscriptionStartTime - 1);
        vm.prank(alice);
        vm.expectRevert(SubscriptionNotActive.selector);
        rwaManager.cancelSubscription(period);

        vm.warp(subscriptionStartTime + 1);
        vm.prank(alice);
        vm.expectRevert(NoUSDCBalance.selector);
        rwaManager.cancelSubscription(period);
    }
}
