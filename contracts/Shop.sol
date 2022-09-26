// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7.0;

abstract contract Sender {
    bool public isSold;
    function buy() external virtual;
}

contract Shop {
  function buy(address _sender) public {
      Sender(_sender).buy();
  }

  function price() public view returns(uint) {
      bool isSold = Sender(msg.sender).isSold();
      if (isSold) {
          return 0;
      } else {
          return 100;
      }
  }
}