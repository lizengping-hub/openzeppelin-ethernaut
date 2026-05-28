// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Address } from "openzeppelin-contracts-v5.4.0/utils/Address.sol";
import { NotOptimisticPortal } from "src/levels/NotOptimisticPortal.sol";

interface IMessageReceiver {
    function onMessageReceived(bytes memory messageData) external;
}

contract MessageReceiver is IMessageReceiver{
    NotOptimisticPortal public immutable portal;
    constructor(NotOptimisticPortal _portal) {
        portal = _portal;
    }

    function onMessageReceived(bytes memory messageData) external{
        require(msg.sender == address(portal), "Only portal can call this function");

        portal.updateSequencer_____76439298743(address(this));
        Address.functionCall(address(portal), abi.encodeWithSelector(portal.submitNewBlock_____37278985983.selector,messageData));
    }
}