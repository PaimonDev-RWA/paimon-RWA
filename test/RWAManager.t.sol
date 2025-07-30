// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../contracts/RWAToken.sol";
import "../contracts/RWAManager.sol";
import "../contracts/Subscription.sol";
import "../contracts/Redemption.sol";
import "../contracts/mocks/USDCMock.sol";

contract RWAManagerTest is Test {
    error InvalidRwaTokenAddress();
    error InvalidUSDCAddress();
    error AccountBlacklisted();
    error InvalidFeeReceiver();
    error InvalidAmount();
    error InsufficientUSDCBalance();
    error InvalidWhale();
    error InvalidMerkleProof();
    error NoUSDCBalance();

    RWAToken public rwaToken;
    RWAManager public rwaManager;
    USDCMock public usdc;
    Subscription public subscription;
    Redemption public redemption;

    // Merkle root and proofs
    bytes32 public root;
    mapping(address => bytes32[]) public proofs;

    address public owner = address(0x1);
    address public admin = address(0x11);
    address public alice = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public bob = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address public carol = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

    uint256 public period = 1;

    // Subscription period: 7 days
    uint256 public subscriptionStartTime = block.timestamp + 1 days;
    uint256 public subscriptionEndTime = subscriptionStartTime + 7 days;

    // Redemption period: 7 days, starts 1 day after subscription ends
    uint256 public redemptionStartTime = subscriptionEndTime + 1 days;
    uint256 public redemptionEndTime = redemptionStartTime + 7 days;

    // Caps for Subscription (USDC, 6 decimals)
    uint256 public subscriptionTotalCap = 1000 * 1e6; // 1000 USDC
    uint256 public subscriptionUserCap = 100 * 1e6;   // 100 USDC

    // Caps for Redemption (RWA, 18 decimals)
    uint256 public redemptionTotalCap = 1000 * 1e18; // 1000 RWA
    uint256 public redemptionUserCap = 100 * 1e18;   // 100 RWA

    // helper function to parse proof
    function _parseProof(string memory json, string memory addressKey) internal pure returns (bytes32[] memory) {
        string memory path = string(abi.encodePacked(".proofs.", addressKey));
        bytes memory proofBytes = vm.parseJson(json, path);
        return abi.decode(proofBytes, (bytes32[]));
    }

    function setUp() public {
        // Deploy mock USDC token
        usdc = new USDCMock(1000000 * 1e6); // 1M USDC (6 decimals)

        // Deploy RWAToken
        vm.prank(owner);
        rwaToken = new RWAToken("RWA Token", "RWA");

        // Deploy RWAManager contract
        vm.prank(owner);
        rwaManager = new RWAManager(address(rwaToken), address(usdc));

        // Set RWAManager as RWAToken's manager
        vm.prank(owner);
        rwaToken.setManager(address(rwaManager));

        // Mint USDC to Alice and Bob for testing
        usdc.mint(alice, 1000 * 1e6); // 1000 USDC (6 decimals)
        usdc.mint(bob, 1000 * 1e6);   // 1000 USDC (6 decimals)

        // Create Subscription and Redemption contracts with appropriate caps
        vm.prank(owner);
        rwaManager.createSubscriptionContract(
            period,
            subscriptionStartTime,
            subscriptionEndTime,
            subscriptionTotalCap,
            subscriptionUserCap
        );

        vm.prank(owner);
        rwaManager.createRedemptionContract(
            period,
            redemptionStartTime,
            redemptionEndTime,
            redemptionTotalCap,
            redemptionUserCap
        );

        // Get deployed contract addresses
        subscription = Subscription(rwaManager.subscriptionContracts(period));
        redemption = Redemption(rwaManager.redemptionContracts(period));

        // setup Merkle data
        string memory json = vm.readFile("./test/merkle-data.json");
        root = vm.parseJsonBytes32(json, ".root");

        vm.prank(owner);
        rwaManager.setAdmin(admin, true);
        vm.prank(owner);
        rwaManager.setPenaltyRatio(20000); // 2% penalty
        vm.prank(admin);
        rwaManager.setMerkleRoot(root);

        // set proofs for each account
        proofs[alice] = _parseProof(json, "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
        proofs[bob] = _parseProof(json, "0x70997970C51812dc3A010C7d01b50e0d17dc79C8");
        proofs[carol] = _parseProof(json, "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC");
    }

    // ========== Helper Functions ==========

    function _warpToActiveSubscriptionPeriod() internal {
        vm.warp(subscriptionStartTime + 1); // Warp to just after the subscription start time
    }

    function _warpToAfterSubscriptionEndTime() internal {
        vm.warp(subscriptionEndTime + 1); // Warp to just after the subscription end time
    }

    function _warpToActiveRedemptionPeriod() internal {
        vm.warp(redemptionStartTime + 1); // Warp to just after the redemption start time
    }

    function _warpToAfterRedemptionEndTime() internal {
        vm.warp(redemptionEndTime + 1); // Warp to just after the redemption end time
    }

    function _subscribeAlice(uint256 usdcAmount) internal {
        // Approve USDC spending
        vm.prank(alice);
        usdc.approve(address(rwaManager), usdcAmount);

        // Alice subscribes
        vm.prank(alice);
        rwaManager.subscribe(period, usdcAmount, proofs[alice]);
    }

    function _setExchangeRateAndClaimable() internal {
        // Set exchange rate (1 USDC = 1 RWA)
        vm.prank(owner);
        subscription.setExchangeRate(1 ether);

        // Set subscription as claimable
        vm.prank(owner);
        subscription.setClaimable(true);
    }

    // ========== Test for RWAManager Constructor ==========

    function testRWAManagerConstructor() public {
        // === Test 1: Constructor initializes correctly ===
        // Check the name and symbol of the token
        assertEq(rwaToken.name(), "RWA Token", "Token name incorrect");
        assertEq(rwaToken.symbol(), "RWA", "Token symbol incorrect");

        // Check the USDC address and decimals
        assertEq(address(rwaManager.USDC()), address(usdc), "USDC address incorrect");
        assertEq(rwaManager.USDC_DECIMALS(), 6, "USDC decimals incorrect");

        // Check the fee receiver is set to the owner
        assertEq(rwaManager.feeReceiver(), owner, "Fee receiver incorrect");

        // === Test 2: Constructor reverts if USDC address is zero ===
        vm.expectRevert(InvalidUSDCAddress.selector);
        new RWAManager(address(rwaToken), address(0));

        // === Test 3: Constructor reverts if RWAToken address is zero ===
        vm.expectRevert(InvalidRwaTokenAddress.selector);
        new RWAManager(address(0), address(usdc));
    }

    // ========== Tests Merkle ==========

    function testVerifyMerkleProof() public view {
        assertTrue(rwaManager.verify(alice, proofs[alice]));
        assertFalse(rwaManager.verify(bob, proofs[alice]));
    }

    // ========== Tests for Subscription ==========

    function testSubscriptionContractCreation() public view {
        assertTrue(address(subscription) != address(0), "Subscription contract not created");
    }

    function testSetExchangeRateForSubscription() public {
        uint256 newRate = 1.5 ether; // 1 USDC = 1.5 RWA

        vm.prank(owner);
        subscription.setExchangeRate(newRate);

        assertEq(subscription.rate(), newRate, "Subscription exchange rate not updated");
    }

    function testSubscribe() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Check Alice's USDC balance in the subscription contract
        uint256 aliceBalance = subscription.userUSDCBalance(alice);
        assertEq(aliceBalance, 100 * 1e6, "Alice's USDC balance incorrect");
        assertEq(rwaManager.getSubscriptionBalance(period, alice), 100 * 1e6);

        vm.prank(alice);
        vm.expectRevert(InvalidMerkleProof.selector);
        rwaManager.subscribe(period, 100 * 1e6, proofs[bob]);
    }

    function testCancelSubscription() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Alice cancels subscription
        vm.prank(alice);
        rwaManager.cancelSubscription(period);

        // Check Alice's USDC balance in the subscription contract
        uint256 aliceBalance = subscription.userUSDCBalance(alice);
        assertEq(aliceBalance, 0, "Alice's USDC balance not reset");
    }

    function testClaimRWAToken() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Warp to after the subscription period ends
        _warpToAfterSubscriptionEndTime();

        // Set exchange rate and mark subscription as claimable
        _setExchangeRateAndClaimable();

        // Alice claims RWA tokens
        vm.prank(alice);
        rwaManager.claimRWAToken(period);

        // Check Alice's RWA token balance
        uint256 aliceRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceRWABalance, 100 * 1e18, "Alice's RWA balance incorrect");
        // claim again
        vm.prank(alice);
        vm.expectRevert(NoUSDCBalance.selector);
        rwaManager.claimRWAToken(period);
        assertEq(aliceRWABalance, 100 * 1e18, "Alice's RWA balance incorrect");
    }

    // ========== Tests for Redemption ==========

    function testRedemptionContractCreation() public view {
        assertTrue(address(redemption) != address(0), "Redemption contract not created");
    }

    function testSetExchangeRateForRedemption() public {
        uint256 newRate = 1.2 ether; // 1 RWA = 1.2 USDC

        vm.prank(owner);
        redemption.setExchangeRate(newRate);

        assertEq(redemption.rate(), newRate, "Redemption exchange rate not updated");
    }

    function testRedeem() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Warp to after the subscription period ends
        _warpToAfterSubscriptionEndTime();

        // Set exchange rate and mark subscription as claimable
        _setExchangeRateAndClaimable();

        // Alice claims RWA tokens
        vm.prank(alice);
        rwaManager.claimRWAToken(period);

        // Check Alice's RWA token balance
        uint256 aliceRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceRWABalance, 100 * 1e18, "Alice's RWA balance incorrect");

        // Warp to the active redemption period
        _warpToActiveRedemptionPeriod();

        // Alice redeems RWA tokens
        vm.prank(alice);
        vm.expectRevert(InvalidMerkleProof.selector);
        rwaManager.redeem(period, 100 * 1e18, proofs[bob]);
        vm.prank(alice);
        rwaManager.redeem(period, 100 * 1e18, proofs[alice]);

        // Check Alice's RWA balance in the redemption contract
        uint256 aliceBalance = redemption.userRWABalance(alice);
        assertEq(aliceBalance, 100 * 1e18, "Alice's RWA balance incorrect");
        assertEq(rwaManager.getRedemptionBalance(period, alice), 100 * 1e18);
    }

    function testCancelRedeem() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Warp to after the subscription period ends
        _warpToAfterSubscriptionEndTime();

        // Set exchange rate and mark subscription as claimable
        _setExchangeRateAndClaimable();

        // Alice claims RWA tokens
        vm.prank(alice);
        rwaManager.claimRWAToken(period);

        // Check Alice's RWA token balance
        uint256 aliceRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceRWABalance, 100 * 1e18, "Alice's RWA balance incorrect");

        // Warp to the active redemption period
        _warpToActiveRedemptionPeriod();

        // Alice redeems RWA tokens
        vm.prank(alice);
        rwaManager.redeem(period, 100 * 1e18, proofs[alice]); // 100 RWA (18 decimals)

        // Alice cancels redemption
        vm.prank(alice);
        rwaManager.cancelRedeem(period);

        // Check Alice's RWA balance in the redemption contract
        uint256 aliceBalance = redemption.userRWABalance(alice);
        assertEq(aliceBalance, 0, "Alice's RWA balance not reset");
        uint256 rwaBalance = rwaToken.balanceOf(alice);
        assertEq(rwaBalance, 100 * 1e18);
    }

    function testClaimUSDC() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Warp to after the subscription period ends
        _warpToAfterSubscriptionEndTime();

        // Set exchange rate and mark subscription as claimable
        _setExchangeRateAndClaimable();

        // Alice claims RWA tokens
        vm.prank(alice);
        rwaManager.claimRWAToken(period);

        // Check Alice's RWA token balance
        uint256 aliceRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceRWABalance, 100 * 1e18, "Alice's RWA balance incorrect");

        // Warp to the active redemption period
        _warpToActiveRedemptionPeriod();

        // Alice redeems RWA tokens
        vm.prank(alice);
        rwaManager.redeem(period, 100 * 1e18, proofs[alice]); // 100 RWA (18 decimals)

        // Simulate time passing to make the redemption claimable
        _warpToAfterRedemptionEndTime();

        // Set exchange rate and claim ratio (assuming 1 RWA = 1 USDC and 100% claim ratio)
        vm.prank(owner);
        redemption.setExchangeRate(1 ether); // 1 RWA = 1 USDC
        vm.prank(owner);
        redemption.setClaimRatio(1e6); // 100% claim ratio

        // Set redemption as claimable
        vm.prank(owner);
        redemption.setClaimable(true);

        // Alice claims USDC
        vm.prank(alice);
        rwaManager.claimUSDC(period);

        // Check Alice's USDC balance
        uint256 aliceUSDCBalance = usdc.balanceOf(alice);
        assertEq(aliceUSDCBalance, 998 * 1e6, "Alice's USDC balance incorrect");

        assertEq(rwaToken.balanceOf(alice), 0);
    }

    // ========== Tests for Admin Functions ==========

    function testSetFeeReceiver() public {
        address feeReceiver = address(0x4);

        // Set a new fee receiver
        vm.prank(owner);
        rwaManager.setFeeReceiver(feeReceiver);

        // Check that the fee receiver was updated
        assertEq(rwaManager.feeReceiver(), feeReceiver, "Fee receiver not updated");

        // Ensure only the owner can set the fee receiver
        vm.prank(alice);
        vm.expectRevert();
        rwaManager.setFeeReceiver(feeReceiver);

        // Ensure the fee receiver cannot be set to the zero address
        vm.prank(owner);
        vm.expectRevert(InvalidFeeReceiver.selector);
        rwaManager.setFeeReceiver(address(0));
    }

    function testSetBlacklist() public {
        // Add Alice to the blacklist
        vm.prank(owner);
        rwaManager.setBlacklist(alice, true);

        // Check that Alice is blacklisted
        assertTrue(rwaManager.blacklistedAddresses(alice), "Alice should be blacklisted");

        // Ensure Alice cannot subscribe
        _warpToActiveSubscriptionPeriod();
        vm.prank(alice);
        usdc.approve(address(rwaManager), 100 * 1e6);
        vm.prank(alice);
        vm.expectRevert(AccountBlacklisted.selector);
        rwaManager.subscribe(period, 100 * 1e6, proofs[alice]);

        // Remove Alice from the blacklist
        vm.prank(owner);
        rwaManager.setBlacklist(alice, false);

        // Check that Alice is no longer blacklisted
        assertFalse(rwaManager.blacklistedAddresses(alice), "Alice should not be blacklisted");

        // Ensure Alice can now subscribe
        vm.prank(alice);
        rwaManager.subscribe(period, 100 * 1e6, proofs[alice]);

        // Ensure only the owner can modify the blacklist
        vm.prank(alice);
        vm.expectRevert();
        rwaManager.setBlacklist(bob, true);
    }

    // ========== Test for withdrawUSDC ==========

    function testWithdrawUSDC() public {
        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Alice subscribes with 100 USDC
        _subscribeAlice(100 * 1e6);

        // Check the contract's USDC balance
        uint256 contractUSDCBalanceBefore = usdc.balanceOf(address(rwaManager));
        assertEq(contractUSDCBalanceBefore, 100 * 1e6, "Contract USDC balance incorrect");

        // === Test 1: Successful withdrawal of USDC by the owner ===
        uint256 withdrawAmount = 50 * 1e6;
        vm.prank(owner);
        rwaManager.withdrawUSDC(withdrawAmount);

        // Check the contract's USDC balance after withdrawal
        uint256 contractUSDCBalanceAfter = usdc.balanceOf(address(rwaManager));
        assertEq(contractUSDCBalanceAfter, 50 * 1e6, "Contract USDC balance incorrect after withdrawal");

        // Check the fee receiver's USDC balance after withdrawal
        uint256 feeReceiverUSDCBalance = usdc.balanceOf(rwaManager.feeReceiver());
        assertEq(feeReceiverUSDCBalance, withdrawAmount, "Fee receiver USDC balance incorrect");

        // === Test 2: Revert if the amount is zero ===
        vm.prank(owner);
        vm.expectRevert(InvalidAmount.selector);
        rwaManager.withdrawUSDC(0);

        // === Test 3: Revert if there is insufficient USDC balance in the contract ===
        uint256 largeWithdrawAmount = 200 * 1e6;
        vm.prank(owner);
        vm.expectRevert(InsufficientUSDCBalance.selector);
        rwaManager.withdrawUSDC(largeWithdrawAmount);

        // === Test 4: Revert if a non-owner tries to withdraw USDC ===
        vm.prank(alice);
        vm.expectRevert(); // Expect revert due to onlyOwner modifier
        rwaManager.withdrawUSDC(withdrawAmount);
    }

    // ========== Test for Full Procedure: Subscribe, Claim RWA, and Redeem with Custom Exchange Rates and 40% Claim Ratio ==========

    function testFullProcedureWithCorrectExchangeRatesAndClaimRatio() public {
        // === Step 1: Subscription Phase ===

        // Warp to the active subscription period
        _warpToActiveSubscriptionPeriod();

        // Set the exchange rate for subscription (1 RWA = 2 USDC)
        uint256 subscriptionRate = 2 ether; // 1 RWA = 2 USDC
        vm.prank(owner);
        subscription.setExchangeRate(subscriptionRate);

        // Alice subscribes with 100 USDC
        uint256 aliceUSDCAmount = 100 * 1e6; // 100 USDC (6 decimals)
        _subscribeAlice(aliceUSDCAmount);

        // Check Alice's USDC balance in the subscription contract
        uint256 aliceUSDCBalance = subscription.userUSDCBalance(alice);
        assertEq(aliceUSDCBalance, aliceUSDCAmount, "Alice's USDC balance incorrect");
        assertEq(usdc.balanceOf(alice), 900 * 1e6); // 1000 - 100

        // Warp to after the subscription period ends
        _warpToAfterSubscriptionEndTime();

        // Set the subscription as claimable
        vm.prank(owner);
        subscription.setClaimable(true);

        // Alice claims RWA tokens
        vm.prank(alice);
        rwaManager.claimRWAToken(period);

        // Calculate Alice's expected RWA balance
        uint256 expectedRWA = aliceUSDCAmount / (subscriptionRate / 1e18) * (1e18 / 1e6); // 100% of 100 USDC / (2 USDC/RWA)
        uint256 aliceRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceRWABalance, expectedRWA, "Alice's RWA balance incorrect after claim");
        assertEq(expectedRWA, 50 * 1e18);
        uint256 aliceTotalRWABalance = rwaToken.balanceOf(alice);
        assertEq(aliceTotalRWABalance, 50 * 1e18);

        // === Step 3: Redemption Phase ===

        // Warp to the active redemption period
        _warpToActiveRedemptionPeriod();

        // Set the exchange rate for redemption (1 RWA = 4 USDC)
        uint256 redemptionRate = 4 ether; // 1 RWA = 4 USDC
        vm.prank(owner);
        redemption.setExchangeRate(redemptionRate);

        // Set the claim ratio to 40% (400,000 in 6 decimals)
        uint256 claimRatio = 400000; // 40%
        vm.prank(owner);
        redemption.setClaimRatio(claimRatio);

        // Alice redeems all her RWA tokens
        vm.prank(alice);
        rwaManager.redeem(period, aliceTotalRWABalance, proofs[alice]);

        // Check Alice's RWA balance in the redemption contract
        uint256 aliceRWAInRedemption = redemption.userRWABalance(alice);
        assertEq(aliceRWAInRedemption, aliceTotalRWABalance, "Alice's RWA balance in redemption contract incorrect");

        // Warp to after the redemption period ends
        _warpToAfterRedemptionEndTime();

        // Set the redemption as claimable
        vm.prank(owner);
        redemption.setClaimable(true);

        // Alice claims USDC
        vm.prank(alice);
        rwaManager.claimUSDC(period);

        // // === Step 4: Verify Results ===
        // Alice has 50 RWA, and 40% of the RWA can be used to claim USDC
        // 50 * 40% = 20
        // 20 RWA will be used to claim USDC
        // 1 RWA = 4 USDC
        // 20 RWA = 80USDC
        // penalty ratio is 2%
        // 80 * (1 - 2%) = 78.4
        uint256 aliceUSDCBalanceAfterRedemption = usdc.balanceOf(alice);
        assertEq(aliceUSDCBalanceAfterRedemption, (900 + 78.4) * 1e6, "Alice's USDC balance incorrect after redemption");
        // 30 RWA refund to Alice
        assertEq(rwaToken.balanceOf(alice), 30 * 1e18);
        // Check Alice's RWA balance in the redemption contract after claiming
        uint256 aliceRWAInRedemptionAfterClaim = redemption.userRWABalance(alice);
        assertEq(aliceRWAInRedemptionAfterClaim, 0, "Alice's RWA balance in redemption contract not reset");
    }
}
