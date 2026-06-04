// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IForta, DoubleEntryPoint} from "../levels/DoubleEntryPoint.sol";

contract DoubleEntryPointDetectionBot {
    IForta public immutable forta;
    address public immutable vault;
    constructor(address _forta, address _vault) {
        forta = IForta(_forta);
        vault = _vault;
    }
    function handleTransaction(address user, bytes calldata msgData) external{
        require(address(forta) == msg.sender, "Unauthorized");
       ( , , address origSender) = abi.decode(msgData[4:], (address, uint256, address));
        if (origSender == vault) {
            forta.raiseAlert(user);
        }
    }
}
