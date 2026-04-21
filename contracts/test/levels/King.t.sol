// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/attacks/KingAttack.sol";
import "forge-std/Test.sol";

import {Ethernaut} from "src/Ethernaut.sol";
import {KingFactory} from "src/levels/KingFactory.sol";
import {King} from "src/levels/King.sol";
import {Level} from "src/levels/base/Level.sol";
import {Utils} from "test/utils/Utils.sol";

contract TestKing is Test, Utils {
    Ethernaut ethernaut;
    King instance;

    address payable owner;
    address payable player;

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        assertTrue(submitLevelInstance(ethernaut, address(instance)));
    }

    function setUp() public {
        address payable[] memory users = createUsers(2);

        owner = users[0];
        vm.label(owner, "Owner");

        player = users[1];
        vm.label(player, "Player");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        KingFactory factory = new KingFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = King(payable(createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.startPrank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public checkSolvedByPlayer{
        new KingAttack{value:0.001 ether + 1 wei}(address(instance));
    }
}
