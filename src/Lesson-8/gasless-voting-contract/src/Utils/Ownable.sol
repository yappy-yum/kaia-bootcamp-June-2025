// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

    address private s_owner;

    /*//////////////////////////////////////////////////////////////
                              constructor
    //////////////////////////////////////////////////////////////*/     

    constructor(address _owner) {
        assembly {
            sstore(0, _owner)
        }
    }

    /*//////////////////////////////////////////////////////////////
                           onlyOwner modifier
    //////////////////////////////////////////////////////////////*/    

    modifier onlyOwner() {
        assembly {
            if iszero(eq(caller(), sload(0))) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 9)
                mstore(add(p, 0x44), "Not Owner")

                revert(p, 0x64)       
            }
        }
        _;
    }    

    /*//////////////////////////////////////////////////////////////
                           Get Owner Address
    //////////////////////////////////////////////////////////////*/    

    function getOwner() public view returns (address owner) {
        assembly {
            owner := sload(0)
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Change Owner Address
    //////////////////////////////////////////////////////////////*/    

    function changeOwner(address newOwner) public onlyOwner {
        assembly {
            sstore(0, newOwner)
        }
    }        

}