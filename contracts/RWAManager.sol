// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {Subscription} from "./Subscription.sol";
import {Redemption} from "./Redemption.sol";
import {RWAToken} from "./RWAToken.sol";

contract RWAManager is Ownable, ReentrancyGuard {
    error InvalidRwaTokenAddress();
    error InvalidUSDCAddress();
    error InvalidFeeReceiver();
    error InvalidAmount();
    error InsufficientUSDCBalance();
    error USDCTransferFailed();
    error AccountBlacklisted();
    error InvalidPeriod();
    error SubscriptionNotActive();
    error NotClaimable();
    error NoUSDCBalance();
    error NoRWABalance();
    error ExchangeRateNotSet();
    error InsufficientUSDCInContract();
    error SubscriptionContractAlreadyExists();
    error RedemptionContractAlreadyExists();
    error OnlyAdminCanCall();
    error InvalidMerkleProof();

    mapping(uint256 => address) public subscriptionContracts;
    mapping(uint256 => address) public redemptionContracts;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public admins;

    ERC20 public immutable USDC;
    RWAToken public immutable RWA_TOKEN;
    uint8 public immutable USDC_DECIMALS;
    uint256 public penaltyRatio; // 6 decimals; 1e6 = 100%;
    address public feeReceiver;
    bytes32 public merkleRoot;

    event SubscriptionContractCreated(uint256 period, address contractAddress);
    event RedemptionContractCreated(uint256 period, address contractAddress);
    event USDCWithdrawn(uint256 amount);
    event RWATokenClaimed(address user, uint256 period, uint256 amount);
    event RedemptionRequested(address user, uint256 period, uint256 amount);
    event RedeemCanceled(address user, uint256 period, uint256 amount);
    event USDCClaimed(address user, uint256 period, uint256 amount);
    event RefundRWA(address user, uint256 amount);
    event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    event SetBlacklist(address account, bool flag);
    event SetAdmin(address account, bool flag);
    event SetPenaltyRatio(uint256 ratio);
    event Penalty(address user, uint256 period, uint256 amount);

    constructor(address rwaToken, address usdc) Ownable(msg.sender) {
        if (rwaToken == address(0)) revert InvalidRwaTokenAddress();
        if (usdc == address(0)) revert InvalidUSDCAddress();
        RWA_TOKEN = RWAToken(rwaToken);
        USDC = ERC20(usdc);
        USDC_DECIMALS = ERC20(usdc).decimals();
        feeReceiver = msg.sender;
    }

    modifier onlyAdmin() {
        if (admins[msg.sender] == false) revert OnlyAdminCanCall();
        _;
    }

    modifier validProof(bytes32[] calldata proof) {
        if (_verify(msg.sender, proof) == false) revert InvalidMerkleProof();
        _;
    }

    // ========== Owner ==========

    function setMerkleRoot(bytes32 _root) external onlyAdmin {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _root;
        emit MerkleRootUpdated(oldRoot, merkleRoot);
    }

    function setPenaltyRatio(uint256 _ratio) external onlyOwner {
        penaltyRatio = _ratio;
        emit SetPenaltyRatio(_ratio);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        if (_feeReceiver == address(0)) revert InvalidFeeReceiver();
        address oldFeeReceiver = feeReceiver;
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(oldFeeReceiver, _feeReceiver);
    }

    function setAdmin(address account, bool flag) external onlyOwner {
        admins[account] = flag;
        emit SetAdmin(account, flag);
    }

    function setBlacklist(address account, bool flag) external onlyOwner {
        blacklistedAddresses[account] = flag;
        emit SetBlacklist(account, flag);
    }

    function createSubscriptionContract(uint256 period, uint256 startTime, uint256 endTime, uint256 totalCap, uint256 userCap) external onlyOwner returns (address) {
        if (subscriptionContracts[period] != address(0)) revert SubscriptionContractAlreadyExists();
        Subscription subscription = new Subscription(startTime, endTime, totalCap, userCap, owner(), address(this));
        subscriptionContracts[period] = address(subscription);
        emit SubscriptionContractCreated(period, address(subscription));
        return address(subscription);
    }

    function createRedemptionContract(uint256 period, uint256 startTime, uint256 endTime, uint256 totalCap, uint256 userCap) external onlyOwner returns (address) {
        if (redemptionContracts[period] != address(0)) revert RedemptionContractAlreadyExists();
        Redemption redemption = new Redemption(startTime, endTime, totalCap, userCap, owner(), address(this));
        redemptionContracts[period] = address(redemption);
        emit RedemptionContractCreated(period, address(redemption));
        return address(redemption);
    }

    // Paimon team withdraw USDC, use it for off-chain investment.
    function withdrawUSDC(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (USDC.balanceOf(address(this)) < amount) revert InsufficientUSDCBalance();
        
        bool success = USDC.transfer(feeReceiver, amount);
        if (!success) revert USDCTransferFailed();
        
        emit USDCWithdrawn(amount);
    }

    // ========== User ==========

    function subscribe(uint256 period, uint256 amount, bytes32[] calldata proof) external nonReentrant validProof(proof) {
        if (blacklistedAddresses[msg.sender]) revert AccountBlacklisted();
        if (subscriptionContracts[period] == address(0)) revert InvalidPeriod();
        if (amount == 0) revert InvalidAmount();
        
        Subscription subscription = Subscription(subscriptionContracts[period]);
        if (!subscription.isActive()) revert SubscriptionNotActive();
        
        // Transfer USDC from user to this contract
        bool success = USDC.transferFrom(msg.sender, address(this), amount);
        if (!success) revert USDCTransferFailed();
        
        // Update user's USDC balance in subscription contract by adding new amount
        subscription.addUserUSDCBalance(msg.sender, amount);
    }

    function cancelSubscription(uint256 period) external nonReentrant {
        if (subscriptionContracts[period] == address(0)) revert InvalidPeriod();
        
        Subscription subscription = Subscription(subscriptionContracts[period]);
        if (!subscription.isActive()) revert SubscriptionNotActive();
        
        uint256 amount = subscription.userUSDCBalance(msg.sender);
        if (amount == 0) revert NoUSDCBalance();
        
        // Reset user's USDC balance in subscription contract
        subscription.resetUserUSDCBalance(msg.sender);
        
        // Return USDC to user
        bool success = USDC.transfer(msg.sender, amount);
        if (!success) revert USDCTransferFailed();
    }

    function claimRWAToken(uint256 period) external returns (uint256 rwaAmount) {
        if (subscriptionContracts[period] == address(0)) revert InvalidPeriod();
        Subscription subscription = Subscription(subscriptionContracts[period]);
        if (!subscription.claimable()) revert NotClaimable();
        uint256 usdcAmount = subscription.userUSDCBalance(msg.sender);
        if (usdcAmount == 0) revert NoUSDCBalance();
        
        uint256 rate = subscription.rate();
        if (rate == 0) revert ExchangeRateNotSet();
        rwaAmount = _convertUSDCToRWA(usdcAmount, rate);
        
        subscription.resetUserUSDCBalance(msg.sender);
        RWA_TOKEN.mintByManager(msg.sender, rwaAmount);
        emit RWATokenClaimed(msg.sender, period, rwaAmount);
    }

    function redeem(uint256 period, uint256 amount, bytes32[] calldata proof) external nonReentrant validProof(proof) {
        if (redemptionContracts[period] == address(0)) revert InvalidPeriod();
        if (amount == 0) revert InvalidAmount();
        
        Redemption redemption = Redemption(redemptionContracts[period]);
        if (!redemption.isActive()) revert SubscriptionNotActive();
        
        redemption.addUserRWABalance(msg.sender, amount);
        RWA_TOKEN.burnByManager(msg.sender, amount);
        emit RedemptionRequested(msg.sender, period, amount);
    }

    function cancelRedeem(uint256 period) external nonReentrant {
        if (redemptionContracts[period] == address(0)) revert InvalidPeriod();
        
        Redemption redemption = Redemption(redemptionContracts[period]);
        if (!redemption.isActive()) revert SubscriptionNotActive();
        
        uint256 amount = redemption.userRWABalance(msg.sender);
        if (amount == 0) revert NoRWABalance();
        
        // Reset user's RWA balance in redemption contract
        redemption.resetUserRWABalance(msg.sender);
        
        // Return RWA to user
        RWA_TOKEN.mintByManager(msg.sender, amount);
        emit RedeemCanceled(msg.sender, period, amount);
    }

    function claimUSDC(uint256 period) external nonReentrant returns (uint256 usdcAmount) {
        if (redemptionContracts[period] == address(0)) revert InvalidPeriod();
        Redemption redemption = Redemption(redemptionContracts[period]);
        if (!redemption.claimable()) revert NotClaimable();
        uint256 rwaAmount = redemption.userRWABalance(msg.sender);
        if (rwaAmount == 0) revert NoRWABalance();

        uint256 claimRatio = redemption.claimRatio();
        uint256 redeemableAmount = rwaAmount * claimRatio / 1e6;
        uint256 refundAmount = rwaAmount - redeemableAmount;
        
        uint256 rate = redemption.rate();
        if (rate == 0) revert ExchangeRateNotSet();
        usdcAmount = _convertRWAToUSDC(redeemableAmount, rate);
        uint256 penalty = usdcAmount * penaltyRatio / 1e6;
        emit Penalty(msg.sender, period, penalty);
        
        usdcAmount = usdcAmount - penalty;
        if (USDC.balanceOf(address(this)) < usdcAmount) revert InsufficientUSDCInContract();
        
        redemption.resetUserRWABalance(msg.sender);
        bool success = USDC.transfer(msg.sender, usdcAmount);
        if (!success) revert USDCTransferFailed();
        emit USDCClaimed(msg.sender, period, usdcAmount);

        RWA_TOKEN.mintByManager(msg.sender, refundAmount);
        emit RefundRWA(msg.sender, refundAmount);
    }

    // ========== Internal Helpers ==========

    function _convertUSDCToRWA(uint256 usdcAmount, uint256 rate) internal view returns (uint256) {
        // Scale USDC amount to 18 decimals to match RWA's decimal precision.
        uint256 scaledUSDCAmount = usdcAmount * 10 ** (18 - USDC_DECIMALS);

        // Apply the exchange rate (rate is in 18 decimals, where 1e18 = 100%).
        return (scaledUSDCAmount * 1e18) / rate;
    }

    function _convertRWAToUSDC(uint256 rwaAmount, uint256 rate) internal view returns (uint256) {
        // Convert RWA (18 decimals) to USDC (scaled to 18 decimals) using the rate (18 decimals).
        // Formula: (rwaAmount * rate) / 10^18
        uint256 usdcAmountScaled = (rwaAmount * rate) / 1e18;

        // Convert the result to USDC's native decimals.
        return usdcAmountScaled / (10 ** (18 - USDC_DECIMALS));
    }

    function _verify(address account, bytes32[] calldata proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // ========== View ==========

    function getSubscriptionBalance(uint256 period, address account) external view returns (uint256) {
        if (subscriptionContracts[period] == address(0)) revert InvalidPeriod();
        Subscription subscription = Subscription(subscriptionContracts[period]);
        return subscription.getUserBalance(account);
    }

    function getRedemptionBalance(uint256 period, address account) external view returns (uint256) {
        if (redemptionContracts[period] == address(0)) revert InvalidPeriod();
        Redemption redemption = Redemption(redemptionContracts[period]);
        return redemption.getUserBalance(account);
    }

    function verify(address account, bytes32[] calldata proof) external view returns (bool) {
        return _verify(account, proof);
    }
}