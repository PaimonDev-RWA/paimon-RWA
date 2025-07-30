// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Subscription is Ownable {
    error StartTimeMustBeLaterThanCurrentTime();
    error StartTimeMustBeLessThanEndTime();
    error SubscriptionAlreadyStarted();
    error TotalCapMustBeGreaterThanZero();
    error UserCapMustBeGreaterThanZero();
    error UserCapExceedsTotalCap();
    error RateMustBeGreaterThanZero();
    error OnlyManagerCanUpdateBalance();
    error TotalCapExceeded();
    error UserCapExceeded();

    address immutable public manager;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalCap;
    uint256 public userCap;
    uint256 public totalBalance;
    uint256 public rate; // 18 decimals; 1e18 = 100%; rate = RWA value / USDC value
    bool public claimable;
    mapping(address => uint256) public userUSDCBalance;

    event SubscriptionTimeUpdated(uint256 newStartTime, uint256 newEndTime);
    event CapsUpdated(uint256 newTotalCap, uint256 newUserCap);
    event ExchangeRateSet(uint256 rate);
    event ClaimableSet(bool status);
    event UserUSDCBalanceUpdated(address user, uint256 amount);

    modifier onlyManager() {
        if (msg.sender != manager) revert OnlyManagerCanUpdateBalance();
        _;
    }

    constructor(uint256 _startTime, uint256 _endTime, uint256 _totalCap, uint256 _userCap, address _owner, address _manager) Ownable(_owner) {
        if (block.timestamp >= _startTime) revert StartTimeMustBeLaterThanCurrentTime();
        if (_startTime >= _endTime) revert StartTimeMustBeLessThanEndTime();
        if (_totalCap == 0) revert TotalCapMustBeGreaterThanZero();
        if (_userCap == 0) revert UserCapMustBeGreaterThanZero();
        if (_userCap > _totalCap) revert UserCapExceedsTotalCap();
        startTime = _startTime;
        endTime = _endTime;
        totalCap = _totalCap;
        userCap = _userCap;
        manager = _manager;
    }

    function setSubscriptionTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        if (block.timestamp >= startTime) revert SubscriptionAlreadyStarted();
        if (block.timestamp >= _startTime) revert StartTimeMustBeLaterThanCurrentTime();
        if (_startTime >= _endTime) revert StartTimeMustBeLessThanEndTime();
        startTime = _startTime;
        endTime = _endTime;
        emit SubscriptionTimeUpdated(_startTime, _endTime);
    }

    function setCaps(uint256 _totalCap, uint256 _userCap) external onlyOwner {
        if (_totalCap == 0) revert TotalCapMustBeGreaterThanZero();
        if (_userCap == 0) revert UserCapMustBeGreaterThanZero();
        if (_userCap > _totalCap) revert UserCapExceedsTotalCap();
        if (block.timestamp >= startTime) revert SubscriptionAlreadyStarted();
        totalCap = _totalCap;
        userCap = _userCap;
        emit CapsUpdated(_totalCap, _userCap);
    }

    function setExchangeRate(uint256 _rate) external onlyOwner {
        if (_rate == 0) revert RateMustBeGreaterThanZero();
        rate = _rate;
        emit ExchangeRateSet(_rate);
    }

    function setClaimable(bool _claimable) external onlyOwner {
        claimable = _claimable;
        emit ClaimableSet(_claimable);
    }

    function addUserUSDCBalance(address user, uint256 amount) external onlyManager {
        if (totalBalance + amount > totalCap) revert TotalCapExceeded();
        if (userUSDCBalance[user] + amount > userCap) revert UserCapExceeded();
        userUSDCBalance[user] = userUSDCBalance[user] + amount;
        totalBalance = totalBalance + amount;
        emit UserUSDCBalanceUpdated(user, userUSDCBalance[user]);
    }

    function resetUserUSDCBalance(address user) external onlyManager {
        if (totalBalance < userUSDCBalance[user]) {
            totalBalance = 0;
        } else {
            totalBalance = totalBalance - userUSDCBalance[user];
        }
        userUSDCBalance[user] = 0;
        emit UserUSDCBalanceUpdated(user, 0);
    }

    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    // ========== View ==========

    function getUserBalance(address account) external view returns (uint256) {
        return userUSDCBalance[account];
    }
}