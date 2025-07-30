# Paimon

Paimon smart contracts connect traditional funds with on-chain assets. Users interact with on-chain smart contracts by depositing USDC into the smart contract and receiving corresponding tokens (similar to fund shares). The project team takes users' USDC for off-chain investments, and the ratio of tokens to USDC will change (similar to fund net value). Users can later redeem their tokens for the corresponding amount of USDC.

The contracts are mainly divided into three parts:

- **RWAToken contract**: An ERC20 contract that serves as proof of users' investment. The amount of RWAToken a user owns represents their fund shares.
- **RWAManager contract**: This contract serves as the main contract, where the project team and users mainly interact. This contract can manage Subscription and Redemption contracts, and mint/burn RWAToken for user.
- **Subscription contract**: A new subscription contract is deployed through the RWAManager contract for each fund subscription period.
- **Redemption contract**: A new redemption contract is deployed through the RWAManager contract for each fund redemption period.

---

## Instructions for the Paimon Team (Owner of RWAManager & RWAToken Contract)

### **Interacting with the RWAToken Contract**

As the owner of the `RWAToken` contract, the Paimon team can interact with the following functions to manage token operations:

1. **Set Manager Contract**
   - **Function**: `setManager(address _manager)`
   - **Description**: Link the RWAManager contract address to enable minting/burning operations during subscription/redemption processes.

2. **Manage Whale List**
   - **Function**: `setWhaleList(address account, bool flag)`
   - **Description**: Add/remove addresses from the whale list. Whale addresses can receive direct token minting/burning.

3. **Mint Tokens for Whale**
   - **Function**: `mintForWhale(address account, uint256 amount)`
   - **Description**: Directly mint RWA tokens to pre-approved whale addresses (bypassing regular subscription channels).

4. **Burn Tokens for Whale**
   - **Function**: `burnForWhale(address account, uint256 amount)`
   - **Description**: Directly burn RWA tokens from pre-approved whale addresses (bypassing regular redemption channels).

5. **Manager-Initiated Minting**
   - **Function**: `mintByManager(address account, uint256 amount)`
   - **Description**: (Called by RWAManager) Mint tokens during user subscriptions. Only executable by the authorized manager.

6. **Manager-Initiated Burning**
   - **Function**: `burnByManager(address account, uint256 amount)`
   - **Description**: (Called by RWAManager) Burn tokens during user redemptions. Only executable by the authorized manager.

### **Interacting with the RWAManager Contract**

As the owner of the `RWAManager` contract, the Paimon team can interact with the following functions to manage the fund and user interactions:

1. **Set Fee Receiver**
   - **Function**: `setFeeReceiver(address _feeReceiver)`
   - **Description**: Set the address where USDC fees will be sent when withdrawn by the team.

2. **Set Blacklist**
   - **Function**: `setBlacklist(address account, bool flag)`
   - **Description**: Add or remove an address from the blacklist. Blacklisted addresses cannot subscribe to the fund.

3. **Create Subscription Contract**
   - **Function**: `createSubscriptionContract(uint256 period, uint256 startTime, uint256 endTime, uint256 totalCap, uint256 userCap)`
   - **Description**: Deploy a new subscription contract for a specific period.

4. **Create Redemption Contract**
   - **Function**: `createRedemptionContract(uint256 period, uint256 startTime, uint256 endTime, uint256 totalCap, uint256 userCap)`
   - **Description**: Deploy a new redemption contract for a specific period.

5. **Withdraw USDC**
   - **Function**: `withdrawUSDC(uint256 amount)`
   - **Description**: Withdraw USDC from the contract for off-chain investments.

### **Interacting with the Subscription Contract**
6. **Set Exchange Rate**
   - **Function**: `Subscription.setExchangeRate(uint256 _rate)`
   - **Description**: Set the exchange rate for a specific subscription period (e.g., 1 RWA = X USDC).

7. **Set Claimable Status**
   - **Function**: `Subscription.setClaimable(bool _claimable)`
   - **Description**: Mark a subscription period as claimable, allowing users to claim their RWA tokens.

### **Interacting with the Redemption Contract**
8. **Set Exchange Rate**
   - **Function**: `Redemption.setExchangeRate(uint256 _rate)`
   - **Description**: Set the exchange rate for a specific redemption period (e.g., 1 RWA = X USDC).

9. **Set Claim Ratio**
   - **Function**: `Redemption.setClaimRatio(uint256 _claimRatio)`
   - **Description**: Set the claim ratio for a specific redemption period (e.g., 50% of the RWA value can be claimed as USDC).

10. **Set Claimable Status**
    - **Function**: `Redemption.setClaimable(bool _claimable)`
    - **Description**: Mark a redemption period as claimable, allowing users to claim their USDC.

---

## Instructions for Users

Users can interact with the following functions to subscribe to the fund, claim RWA tokens, redeem RWA tokens, and claim USDC:

### **Interacting with the RWAManager Contract**
1. **Subscribe**
   - **Function**: `subscribe(uint256 period, uint256 amount)`
   - **Description**: Deposit USDC into the subscription contract for a specific period to receive RWA tokens.

2. **Cancel Subscription**
   - **Function**: `cancelSubscription(uint256 period)`
   - **Description**: Cancel a subscription and get the deposited USDC back.

3. **Claim RWA Tokens**
   - **Function**: `claimRWAManager(uint256 period)`
   - **Description**: Claim RWA tokens after the subscription period ends and the period is marked as claimable.

4. **Redeem RWA Tokens**
   - **Function**: `redeem(uint256 period, uint256 amount)`
   - **Description**: Redeem RWA tokens during the redemption period to receive USDC later.

5. **Cancel Redemption**
   - **Function**: `cancelRedeem(uint256 period)`
   - **Description**: Cancel a redemption request and get the RWA tokens back.

6. **Claim USDC**
   - **Function**: `claimUSDC(uint256 period)`
   - **Description**: Claim USDC after the redemption period ends and the period is marked as claimable.

---

## Workflow Example

1. **Subscription**:
   - The Paimon team deploys a subscription contract for a new period.
   - Users subscribe by depositing USDC and receive RWA tokens based on the exchange rate.

2. **Redemption**:
   - The Paimon team deploys a redemption contract for a new period.
   - Users redeem their RWA tokens and receive USDC based on the exchange rate and claim ratio.