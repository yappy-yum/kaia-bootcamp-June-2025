// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReentrancyGuard {

    modifier noReentrant() {
        assembly {
            if tload(0) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 14)
                mstore(add(p, 0x44), "No Reenterant!")

                revert(p, 0x64)
            }
            tstore(0, 1)
        }
        _;
        assembly { tstore(0, 0) }
    }

}