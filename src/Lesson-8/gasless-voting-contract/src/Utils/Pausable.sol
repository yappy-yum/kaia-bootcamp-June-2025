// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Pausable {

    bool private isPause;

    /**
     * Emergency pause 
     *
     */
    modifier emergency() {
        assembly {
            if iszero(eq(sload(isPause.slot), true)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 6)
                mstore(add(p, 0x44), "Paused")

                revert(p, 0x64)
            }
        }
        _;
    }

    function _setPause() internal {
        isPause = !isPause;
    }

}