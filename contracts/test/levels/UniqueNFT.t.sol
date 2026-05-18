// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../../src/attacks/UniqueNFTAttack.sol";
import "forge-std/Test.sol";

import {Ethernaut} from "src/Ethernaut.sol";
import {Level} from "src/levels/base/Level.sol";
import {UniqueNFTFactory} from "src/levels/UniqueNFTFactory.sol";
import {UniqueNFT} from "src/levels/UniqueNFT.sol";
import {Utils} from "test/utils/Utils.sol";


contract TestUniqueNFT is Test, Utils {
    Ethernaut ethernaut;
    UniqueNFT instance;

    address payable owner;
    address player;
    uint256 playerKey;

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        assertTrue(submitLevelInstance(ethernaut, address(instance)));
    }

    function setUp() public {
        address payable[] memory users = createUsers(1);

        owner = users[0];
        vm.label(owner, "Owner");

        (player, playerKey) = makeAddrAndKey("Player");
        vm.label(player, "Player");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        UniqueNFTFactory factory = new UniqueNFTFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = UniqueNFT(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the initial state of the level and environment.
    function testInit() public {
        vm.startPrank(player);
        assertEq(instance.balanceOf(player), 0);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    function testEOACanOnlyMintOnce() public {
        vm.startPrank(player, player);
        instance.mintNFTEOA();

        vm.expectRevert("only one unique NFT allowed");
        instance.mintNFTEOA();
    }

    /// @notice Test the solution for the level.
    function testSolve() public checkSolvedByPlayer {
        UniqueNFTAttack attacker = new UniqueNFTAttack();

        vm.signAndAttachDelegation(address(attacker), playerKey);
        UniqueNFTAttack(payable(player)).setNFT(instance);
        UniqueNFTAttack(payable(player)).attack();
    }
}
