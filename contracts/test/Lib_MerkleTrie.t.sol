// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import { Lib_MerkleTrie } from "src/helpers/lib/trie/Lib_MerkleTrie.sol";
import { Lib_RLPWriter } from "src/helpers/lib/rlp/Lib_RLPWriter.sol";

contract TrieExampleTest is Test {
    using Lib_RLPWriter for bytes;
    using Lib_RLPWriter for bytes[];

    function _empty() internal pure returns (bytes memory) {
        return Lib_RLPWriter.writeBytes(bytes(""));
    }

    function _ref(bytes memory node) internal pure returns (bytes memory) {
        if (node.length < 32) {
            return node;
        }
        return Lib_RLPWriter.writeBytes(abi.encodePacked(keccak256(node)));
    }

    function _branch(uint8 childIndex, bytes memory childRef) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](17);
        for (uint256 i = 0; i < 17; i++) {
            items[i] = _empty();
        }
        items[childIndex] = childRef;
        return Lib_RLPWriter.writeList(items);
    }

    function _branch2(
        uint8 childIndexA,
        bytes memory childRefA,
        uint8 childIndexB,
        bytes memory childRefB
    ) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](17);
        for (uint256 i = 0; i < 17; i++) {
            items[i] = _empty();
        }
        items[childIndexA] = childRefA;
        items[childIndexB] = childRefB;
        return Lib_RLPWriter.writeList(items);
    }

    function _extension(bytes memory compactPath, bytes memory childRef) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](2);
        items[0] = Lib_RLPWriter.writeBytes(compactPath);
        items[1] = childRef;
        return Lib_RLPWriter.writeList(items);
    }

    function _leaf(bytes memory compactPath, bytes memory value) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](2);
        items[0] = Lib_RLPWriter.writeBytes(compactPath);
        items[1] = Lib_RLPWriter.writeBytes(value);
        return Lib_RLPWriter.writeList(items);
    }

    function testTrie112Proof() public {
        // We use byte keys 0x0120, 0x1100, 0x1120, 0x2100 so their nibble paths are
        // [0,1,2,0], [1,1,0,0], [1,1,2,0], [2,1,0,0]. The last zero is padding so
        // the three-digit examples can be represented as whole bytes.
        bytes memory leaf012 = _leaf(hex"30", hex"0120");
        bytes memory leaf110 = _leaf(hex"30", hex"1100");
        bytes memory leaf112 = _leaf(hex"30", hex"1120");
        bytes memory leaf210 = _leaf(hex"30", hex"2100");

        bytes memory branch012 = _branch(2, _ref(leaf012));
        bytes memory branch11x = _branch2(0, _ref(leaf110), 2, _ref(leaf112));
        bytes memory branch210 = _branch(0, _ref(leaf210));

        bytes memory branch01 = _branch(1, _ref(branch012));
        bytes memory branch11 = _branch(1, _ref(branch11x));
        bytes memory branch21 = _branch(1, _ref(branch210));

        bytes[] memory rootItems = new bytes[](17);
        for (uint256 i = 0; i < 17; i++) {
            rootItems[i] = _empty();
        }
        rootItems[0] = _ref(branch01);
        rootItems[1] = _ref(branch11);
        rootItems[2] = _ref(branch21);
        bytes memory root = Lib_RLPWriter.writeList(rootItems);
        bytes32 rootHash = keccak256(root);

        bytes[] memory proofItems = new bytes[](4);
        proofItems[0] = Lib_RLPWriter.writeBytes(root);
        proofItems[1] = Lib_RLPWriter.writeBytes(branch11);
        proofItems[2] = Lib_RLPWriter.writeBytes(branch11x);
        proofItems[3] = Lib_RLPWriter.writeBytes(leaf112);
        bytes memory proof = Lib_RLPWriter.writeList(proofItems);

        (bool exists, bytes memory value) = Lib_MerkleTrie.get(hex"1120", proof, rootHash);
        assertTrue(exists);
        assertEq(value, hex"1120");

        bytes[] memory proof110Items = new bytes[](4);
        proof110Items[0] = Lib_RLPWriter.writeBytes(root);
        proof110Items[1] = Lib_RLPWriter.writeBytes(branch11);
        proof110Items[2] = Lib_RLPWriter.writeBytes(branch11x);
        proof110Items[3] = Lib_RLPWriter.writeBytes(leaf110);
        bytes memory proof110 = Lib_RLPWriter.writeList(proof110Items);

        (bool exists110, bytes memory value110) = Lib_MerkleTrie.get(hex"1100", proof110, rootHash);
        assertTrue(exists110);
        assertEq(value110, hex"1100");

        console.log("leaf012");
        console.logBytes(leaf012);
        console.logBytes32(keccak256(leaf012));
        console.log("leaf110");
        console.logBytes(leaf110);
        console.logBytes32(keccak256(leaf110));
        console.log("leaf112");
        console.logBytes(leaf112);
        console.logBytes32(keccak256(leaf112));
        console.log("leaf210");
        console.logBytes(leaf210);
        console.logBytes32(keccak256(leaf210));
        console.log("branch012");
        console.logBytes(branch012);
        console.logBytes32(keccak256(branch012));
        console.log("branch11x");
        console.logBytes(branch11x);
        console.logBytes32(keccak256(branch11x));
        console.log("branch210");
        console.logBytes(branch210);
        console.logBytes32(keccak256(branch210));
        console.log("branch01");
        console.logBytes(branch01);
        console.logBytes32(keccak256(branch01));
        console.log("branch11");
        console.logBytes(branch11);
        console.logBytes32(keccak256(branch11));
        console.log("branch21");
        console.logBytes(branch21);
        console.logBytes32(keccak256(branch21));
        console.log("root");
        console.logBytes(root);
        console.logBytes32(rootHash);
        console.log("proof112");
        console.logBytes(proof);
        console.log("proof110");
        console.logBytes(proof110);
    }
    function testCompressedTrieProofs() public {
        // We use byte keys 0x0120, 0x1100, 0x1120, 0x2100 so their nibble paths are
        // [0,1,2,0], [1,1,0,0], [1,1,2,0], [2,1,0,0]. The last zero is padding so
        // the three-digit examples can be represented as whole bytes.
        //
        // Compressed shape:
        //
        // root
        //   child0 -> leaf(path [1,2,0], value 0120)
        //   child1 -> extension(path [1]) -> branch11x
        //                               child0 -> leaf(path [0], value 1100)
        //                               child2 -> leaf(path [0], value 1120)
        //   child2 -> leaf(path [1,0,0], value 2100)
        bytes memory leaf012 = _leaf(hex"3120", hex"0120");
        bytes memory leaf110 = _leaf(hex"30", hex"1100");
        bytes memory leaf112 = _leaf(hex"30", hex"1120");
        bytes memory leaf210 = _leaf(hex"3100", hex"2100");

        bytes memory branch11x = _branch2(0, _ref(leaf110), 2, _ref(leaf112));
        bytes memory extension11 = _extension(hex"11", _ref(branch11x));

        bytes[] memory rootItems = new bytes[](17);
        for (uint256 i = 0; i < 17; i++) {
            rootItems[i] = _empty();
        }
        rootItems[0] = _ref(leaf012);
        rootItems[1] = _ref(extension11);
        rootItems[2] = _ref(leaf210);
        bytes memory root = Lib_RLPWriter.writeList(rootItems);
        bytes32 rootHash = keccak256(root);

        bytes[] memory proofItems = new bytes[](4);
        proofItems[0] = Lib_RLPWriter.writeBytes(root);
        proofItems[1] = Lib_RLPWriter.writeBytes(extension11);
        proofItems[2] = Lib_RLPWriter.writeBytes(branch11x);
        proofItems[3] = Lib_RLPWriter.writeBytes(leaf112);
        bytes memory proof = Lib_RLPWriter.writeList(proofItems);

        (bool exists, bytes memory value) = Lib_MerkleTrie.get(hex"1120", proof, rootHash);
        assertTrue(exists);
        assertEq(value, hex"1120");

        bytes[] memory proof110Items = new bytes[](4);
        proof110Items[0] = Lib_RLPWriter.writeBytes(root);
        proof110Items[1] = Lib_RLPWriter.writeBytes(extension11);
        proof110Items[2] = Lib_RLPWriter.writeBytes(branch11x);
        proof110Items[3] = Lib_RLPWriter.writeBytes(leaf110);
        bytes memory proof110 = Lib_RLPWriter.writeList(proof110Items);

        (bool exists110, bytes memory value110) = Lib_MerkleTrie.get(hex"1100", proof110, rootHash);
        assertTrue(exists110);
        assertEq(value110, hex"1100");

        console.log("leaf012");
        console.logBytes(leaf012);
        console.logBytes32(keccak256(leaf012));
        console.log("leaf110");
        console.logBytes(leaf110);
        console.logBytes32(keccak256(leaf110));
        console.log("leaf112");
        console.logBytes(leaf112);
        console.logBytes32(keccak256(leaf112));
        console.log("leaf210");
        console.logBytes(leaf210);
        console.logBytes32(keccak256(leaf210));
        console.log("branch11x");
        console.logBytes(branch11x);
        console.logBytes32(keccak256(branch11x));
        console.log("extension11");
        console.logBytes(extension11);
        console.logBytes32(keccak256(extension11));
        console.log("root");
        console.logBytes(root);
        console.logBytes32(rootHash);
        console.log("proof112");
        console.logBytes(proof);
        console.log("proof110");
        console.logBytes(proof110);
    }
}
