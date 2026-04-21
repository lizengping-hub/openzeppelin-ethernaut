// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ReentranceInterface {
    function balances(address) external returns (uint256);
    function donate(address) external payable;
    function balanceOf(address) external returns (uint256);
    function withdraw(uint256) external;
}
