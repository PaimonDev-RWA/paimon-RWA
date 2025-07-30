// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Redemption is Ownable {
    error StartTimeMustBeLaterThanCurrentTime();
    error StartTimeMustBeLessThanEndTime();
    error RedemptionAlreadyStarted();
    error TotalCapMustBeGreaterThanZero();
    error UserCapMustBeGreaterThanZero();
    error UserCapExceedsTotalCap();
    error RateMustBeGreaterThanZero();
    error ClaimRatioMustBeGreaterThanZero();
    error ClaimRatioExceedsMaximum();
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
    uint256 public claimRatio; // 6 decimals; 1e6 = 100%;
    bool public claimable;
    mapping(address => uint256) public userRWABalance;

    event RedemptionTimeUpdated(uint256 newStartTime, uint256 newEndTime);
    event CapsUpdated(uint256 newTotalCap, uint256 newUserCap);
    event ExchangeRateSet(uint256 rate);
    event ClaimableSet(bool status);
    event UserRWABalanceUpdated(address user, uint256 amount);
    event SetClaimRatio(uint256 ratio);

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
        claimRatio = 1e6;
    }

    function setRedemptionTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        if (block.timestamp >= startTime) revert RedemptionAlreadyStarted();
        if (block.timestamp >= _startTime) revert StartTimeMustBeLaterThanCurrentTime();
        if (_startTime >= _endTime) revert StartTimeMustBeLessThanEndTime();
        startTime = _startTime;
        endTime = _endTime;
        emit RedemptionTimeUpdated(_startTime, _endTime);
    }

    function setCaps(uint256 _totalCap, uint256 _userCap) external onlyOwner {
        if (_totalCap == 0) revert TotalCapMustBeGreaterThanZero();
        if (_userCap == 0) revert UserCapMustBeGreaterThanZero();
        if (_userCap > _totalCap) revert UserCapExceedsTotalCap();
        if (block.timestamp >= startTime) revert RedemptionAlreadyStarted();
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

    function setClaimRatio(uint256 _claimRatio) external onlyOwner {
        if (_claimRatio == 0) revert ClaimRatioMustBeGreaterThanZero();
        if (_claimRatio > 1e6) revert ClaimRatioExceedsMaximum();
        claimRatio = _claimRatio;
        emit SetClaimRatio(_claimRatio);
    }

    function addUserRWABalance(address user, uint256 amount) external onlyManager {
        if (totalBalance + amount > totalCap) revert TotalCapExceeded();
        if (userRWABalance[user] + amount > userCap) revert UserCapExceeded();
        userRWABalance[user] = userRWABalance[user] + amount;
        totalBalance = totalBalance + amount;
        emit UserRWABalanceUpdated(user, userRWABalance[user]);
    }

    function resetUserRWABalance(address user) external onlyManager {
        if (totalBalance < userRWABalance[user]) {
            totalBalance = 0;
        } else {
            totalBalance = totalBalance - userRWABalance[user];
        }
        userRWABalance[user] = 0;
        emit UserRWABalanceUpdated(user, 0);
    }

    // ========== View ==========

    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function getUserBalance(address account) external view returns (uint256) {
        return userRWABalance[account];
    }
}