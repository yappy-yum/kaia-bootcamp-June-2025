// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Season } from "src/Utils/Season.sol";
import { Ownable } from "./Utils/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Vote is Season, Ownable {

    error Vote__EmptyIsGiven();
    error Vote__AlreadyCalculated();
    error Vote__Claimed();
    error Vote__VerifyFailed();
    error Vote__NotWinner();
    error Vote__transferFailed();

    /**
     * half of the totalRewards will be given to all the voter who has
     * voted the winner candidate
     *
     * remainder:
     * 1/2 -> manager
     * 1/2 -> Registry contract
     *
     * In short:
     * 0.5 -> voter
     * 0.25 -> manager
     * 0.25 -> Registry contract
     *
     */
    uint immutable private s_totalRewards;
    uint private s_UserRewards; // s_totalRewards * 1/2 / total user

    mapping(uint _voteeId => string _metadata) private s_candidates;
    mapping(address _voter => bool claimed) private s_isClaimed;

    uint private s_WinnerId; // winner votee id
    uint[] private s_voteResult; // index == voteeId
    bytes32 private s_merkleRoot;

    /*//////////////////////////////////////////////////////////////
                              constructor
    //////////////////////////////////////////////////////////////*/    

    constructor(string[] memory _metadatas, address _manager, uint supply) Ownable(_manager) {
        assembly {
            if or(lt(mload(_metadatas), 2), iszero(gt(supply, 1000000000000000000))) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 9)
                mstore(add(p, 0x44), "Need More")

                revert(p, 0x64)
            }
        }

        assembly {
            if iszero(_manager) {
                let p := mload(0x40)

                mstore(p, shl(224, 0x08c379a0))
                mstore(add(p, 0x04), 0x20)
                mstore(add(p, 0x24), 12)
                mstore(add(p, 0x44), "Zero Address")

                revert(p, 0x64)
            }
        }     

        s_totalRewards = supply;
        for (uint i = 0; i < _metadatas.length; i++) {
            s_candidates[i] = _metadatas[i];
        }
    }

    function StopVote(
        uint[] memory _voteResult, 
        uint totalUsers, 
        uint WinnerId,
        bytes32 _merkleRoot
    ) external onlyOwner inProgress 
    {
        if (totalUsers <= 0 || _merkleRoot == bytes32(0)) revert Vote__EmptyIsGiven();
        if (s_UserRewards == 0 || s_merkleRoot != bytes32(0)) revert Vote__AlreadyCalculated();

        // Note:
        // User rewards simple math
        // 
        //  ┌                     ┐
        //  │ ┌                 ┐ │ 
        //  │ │  total rewards  │ │
        //  │ │ --------------- │ │
        //  │ │        2        │ │
        //  │ └                 ┘ │
        //  │ ------------------- │
        //  │     total users     │
        //  └                     ┘
        // 
        // Simplified:
        // 
        //   ┌                    ┐ 
        //   │    total rewards   │ 
        //   │ ------------------ │ 
        //   │  2 * total users   │ 
        //   └                    ┘ 

        s_UserRewards = s_totalRewards / (2 * totalUsers);
        s_merkleRoot = _merkleRoot;
        s_WinnerId = WinnerId;
        s_voteResult = _voteResult;

        _incState();
        _helpIncState();
    }

    function claim(uint candidateId, bytes32 leaf, bytes32[] calldata proof) external finished {
        if (s_isClaimed[msg.sender]) revert Vote__Claimed();
        if (candidateId != s_WinnerId) revert Vote__NotWinner();

        bool Exist = MerkleProof.verifyCalldata(proof, s_merkleRoot, leaf);
        if (!Exist) revert Vote__VerifyFailed();

        s_isClaimed[msg.sender] = true;

        (bool ok, ) = msg.sender.call{value: s_UserRewards}("");
        if (!ok) revert Vote__transferFailed();
    }

    /**
     * @notice straight away close the voting event if all the funds 
     * @notice by candidate has been collected 
     *
     */
    function _helpIncState() internal {
        if (address(this).balance >= s_totalRewards) {
            _incState();
        }
    }

    receive() external payable { _helpIncState(); }

}