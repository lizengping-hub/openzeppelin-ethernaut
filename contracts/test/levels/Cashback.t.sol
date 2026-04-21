// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Cashback, Currency} from "src/levels/Cashback.sol";
import {CashbackFactory, SuperCashbackNFT} from "src/levels/CashbackFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestCashback is Test, Utils {
    Ethernaut ethernaut;
    Cashback instance;
    CashbackFactory factory;

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
        address payable[] memory users = createUsers(2);

        owner = users[0];
        vm.label(owner, "Owner");

        (player, playerKey) = makeAddrAndKey("Player");
        vm.deal(player, 1 ether);

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        factory = new CashbackFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Cashback(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.startPrank(player);
        // Assert Cashback Rates
        assertEq(instance.cashbackRates(Currency.wrap(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE))), 50);
        assertEq(instance.cashbackRates(Currency.wrap(address(factory.FREE()))), 200);
        assertEq(instance.maxCashback(Currency.wrap(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE))), 1 ether);
        assertEq(instance.maxCashback(Currency.wrap(address(factory.FREE()))), 500 ether);

        assertEq(SuperCashbackNFT(instance.superCashbackNFT()).owner(), address(instance));
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public checkSolvedByPlayer{

    }
}
