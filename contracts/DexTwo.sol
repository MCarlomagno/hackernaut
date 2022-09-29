// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexTwoToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DexTwoToken", "DTT") {
        _mint(msg.sender, initialSupply);
    }
}