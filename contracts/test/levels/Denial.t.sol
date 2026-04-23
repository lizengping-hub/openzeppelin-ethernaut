// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Denial} from "src/levels/Denial.sol";
import {DenialFactory} from "src/levels/DenialFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {DenialAttack} from "../../src/attacks/DenialAttack.sol";

contract TestDenial is Test, Utils {
    Ethernaut ethernaut;
    Denial instance;

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
        DenialFactory factory = new DenialFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Denial(payable(createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.prank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public checkSolvedByPlayer{
        DenialAttack a = new DenialAttack();
        instance.setWithdrawPartner(address(a));
        console.logAddress(instance.partner());
        console.logAddress(instance.owner());
    }
}
