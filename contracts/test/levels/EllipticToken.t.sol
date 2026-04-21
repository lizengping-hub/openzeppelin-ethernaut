// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {EllipticToken} from "src/levels/EllipticToken.sol";
import {EllipticTokenFactory} from "src/levels/EllipticTokenFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestEllipticToken is Test, Utils {
    Ethernaut ethernaut;
    EllipticToken instance;

    address payable initializer;
    address player;
    uint256 playerKey;

    uint256 INITIAL_AMOUNT = 10 ether;
    address ALICE = 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e;
    address BOB = 0xB0B14927389CB009E0aabedC271AC29320156Eb8;

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

        initializer = users[0];
        vm.label(initializer, "Initializer");

        (player, playerKey) = makeAddrAndKey("Player");

        vm.startPrank(initializer);
        ethernaut = getEthernautWithStatsProxy(initializer);
        EllipticTokenFactory factory = new EllipticTokenFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = EllipticToken(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the initial state of the level and environment.
    function testInit() public {
        vm.startPrank(player);
        assertEq(instance.balanceOf(ALICE), 10 ether);
        assertEq(instance.owner(), BOB);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public checkSolvedByPlayer{

    }
}
