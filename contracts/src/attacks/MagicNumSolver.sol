// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNumSolver {
    constructor() {
        assembly {
        // This is the bytecode we want the program to have:
        // 00 PUSH1 2a /* push dec 42 (hex 0x2a) onto the stack */ code: 60 2a
        // 03 PUSH1  0 /* store 42 at memory position 0 */ code: 60 00
        // 05 MSTORE code: 52
        // 06 PUSH1 20 /* return 32 bytes in memory */ code: 60 20
        // 08 PUSH1 0 code: 60 00
        // 10 RETURN code: f3
        // Bytecode: 0x602a60005260206000f3 (length 0x0a or 10)
        // Bytecode within a 32 byte word:
        // 0x00000000000000000000000000000000000000000000604260005260206000f3 (length 0x20 or 32)
        //                                               ^ (offset 0x16 or 22)



//            mstore(0, 0x602a60005260206000f3)
//            return(0x16, 0x0a)


        // my
        // This is the bytecode we want the program to have:
        // 00 PUSH1 2a /* push dec 42 (hex 0x2a) onto the stack */ code: 60 2a
        // 03 PUSH0 /* store 42 at memory position 0 */ code: 5f
        // 05 MSTORE code: 52
        // 06 PUSH1 20 /* return 32 bytes in memory */ code: 60 20
        // 08 PUSH0 code: 5f
        // 10 RETURN code: f3
        // Bytecode: 0x602a60005260206000f3 (length 0x0a or 10)
        // Bytecode within a 32 byte word:
        // 0x000000000000000000000000000000000000000000000000602a5f5260205ff3 (length 0x20 or 32)
        //                                                   ^ (offset 0x18 or 24)

            mstore(0, 0x602a5f5260205ff3)
            return(0x18, 0x08)


        }
    }
}
