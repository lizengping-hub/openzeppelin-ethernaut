// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IForta} from "../levels/DoubleEntryPoint.sol";

contract DoubleEntryPointDetectionBot {
    IForta public immutable forta;
    constructor(address _forta){
        forta = IForta(_forta);
    }
    function handleTransaction(address user, bytes calldata msgData) external{
        require(address(forta) == msg.sender, "Unauthorized");
        forta.raiseAlert(user);
    }
}
