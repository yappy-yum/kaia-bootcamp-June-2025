// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Counter {

    uint private s_counter;
    // uint private MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function getCounter() public view returns(uint) {
        return s_counter;
    }

    function _inc() internal {
        assembly {
            let q := sload(s_counter.slot)

            if eq(q, not(0)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 8)
                mstore(add(p, 0x44), "Overflow")

                revert(p, 0x64)                
            }

            sstore(s_counter.slot, add(q, 1))
        }
    }

    function _dec() internal {
        assembly {
            let q := sload(s_counter.slot)

            if eq(q, 0) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 9)
                mstore(add(p, 0x44), "Underflow")

                revert(p, 0x64)
            }

            sstore(s_counter.slot, sub(q, 1))
        }
    }

}