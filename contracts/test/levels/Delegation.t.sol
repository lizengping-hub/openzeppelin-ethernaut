// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Delegation, Delegate} from "src/levels/Delegation.sol";
import {DelegationFactory} from "src/levels/DelegationFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {Address} from "openzeppelin-contracts-v5.4.0/utils/Address.sol";

contract TestDelegation is Test, Utils {
    using Address for address;
    Ethernaut ethernaut;
    Delegation instance;

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
        DelegationFactory factory = new DelegationFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Delegation(createLevelInstance(ethernaut, Level(address(factory)), 0));
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
        address(instance).functionCall(abi.encodeCall(Delegate.pwn, ()));
    }
}
