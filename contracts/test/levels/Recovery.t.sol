// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Recovery, SimpleToken} from "src/levels/Recovery.sol";
import {RecoveryFactory} from "src/levels/RecoveryFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {Lib_RLPReader} from "../../src/helpers/lib/rlp/Lib_RLPReader.sol";

contract TestRecovery is Test, Utils {
    Ethernaut ethernaut;
    Recovery instance;

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
        RecoveryFactory factory = new RecoveryFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Recovery(payable(createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether)));
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
        /*
         * address(
            uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), address(instance), uint8(0x01)))))
        );
         */
        //0xd6 = 214 = 192 + 22
        //0x94 = 148 = 128 + 20
        bytes memory rlp = abi.encodePacked(uint8(0xd6), uint8(0x94), address(instance), uint8(0x01));
        console.logBytes(rlp);
        console.logUint(rlp.length);
        SimpleToken token = SimpleToken(payable(vm.computeCreateAddress(address(instance), 1)));
        token.destroy(payable(address(player)));

    }
}
