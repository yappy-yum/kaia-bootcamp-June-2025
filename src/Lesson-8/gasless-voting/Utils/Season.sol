// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Season {

    enum state {
        GettingReady,   // Setting up candidates
        InProgress,     // user starts voting
        Calculating,    // Calculating result + candidates send funds
        Terminated      // voting is over, user can claim rewards
    }
    state private s_currentState;

    /*//////////////////////////////////////////////////////////////
                                modifier
    //////////////////////////////////////////////////////////////*/  

    modifier gettingReady() {
        assembly {
            if iszero(eq(sload(s_currentState.slot), 0)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 11)
                mstore(add(p, 0x44), "Not Started")

                revert(p, 0x64)
            }
        }
        _;
    }  

    modifier inProgress() {
        assembly {
            if iszero(eq(sload(s_currentState.slot), 1)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 14)
                mstore(add(p, 0x44), "Not InProgress")

                revert(p, 0x64)
            }
        }
        _;
    }

    modifier collectingResult() {
        assembly {
            if iszero(eq(sload(s_currentState.slot), 2)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 7)
                mstore(add(p, 0x44), "Not Now")

                revert(p, 0x64)
            }
        }
        _;
    }

    modifier finished() {
        assembly {
            if iszero(eq(sload(s_currentState.slot), 3)) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 9)
                mstore(add(p, 0x44), "Not Ended")

                revert(p, 0x64)
            }
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 Getter
    //////////////////////////////////////////////////////////////*/    

    function getCurrentState() public view returns (state currentState) {
        assembly {
            currentState := sload(s_currentState.slot)
        }
    }   

    /*//////////////////////////////////////////////////////////////
                              Change State
    //////////////////////////////////////////////////////////////*/    

    function _incState() internal {
        // ensures valid state
        assembly{
            if eq(sload(s_currentState.slot), 3) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 5)
                mstore(add(p, 0x44), "Ended")

                revert(p, 0x64)
            }
        }

        // set state
        assembly {
            let slot := s_currentState.slot
            sstore(
                slot, 
                add(sload(slot), 1)
            )
        }
    } 

}