// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RWAToken is ERC20, Ownable {

    error InvalidManager();
    error InvalidWhale();

    address public manager;
    mapping(address => bool) public whaleListAddresses;

    event SetManager(address manager);
    event SetWhaleList(address account, bool flag);
    event MintForWhale(address account, uint256 amount);
    event BurnForWhale(address account, uint256 amount);
    event MintByManager(address account, uint256 amount);
    event BurnByManager(address account, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit SetManager(_manager);
    }

    function setWhaleList(address account, bool flag) external onlyOwner {
        whaleListAddresses[account] = flag;
        emit SetWhaleList(account, flag);
    }

    function mintForWhale(address account, uint256 amount) external onlyOwner {
        if (whaleListAddresses[account] == false) revert InvalidWhale();
        _mint(account, amount);
        emit MintForWhale(account, amount);
    }

    function burnForWhale(address account, uint256 amount) external onlyOwner {
        if (whaleListAddresses[account] == false) revert InvalidWhale();
        _burn(account, amount);
        emit BurnForWhale(account, amount);
    }

    function mintByManager(address account, uint256 amount) external {
        if (msg.sender != manager) revert InvalidManager();
        _mint(account, amount);
        emit MintByManager(account, amount);
    }

    function burnByManager(address account, uint256 amount) external {
        if (msg.sender != manager) revert InvalidManager();
        _burn(account, amount);
        emit BurnByManager(account, amount);
    }
}