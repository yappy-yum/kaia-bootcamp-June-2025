// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Season } from "../gasless-voting/Utils/Season.sol";
import { Ownable } from "../gasless-voting/Utils/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Registry } from "../gasless-voting/Registry.sol";
import { ReentrancyGuard } from "../gasless-voting/Utils/ReentrancyGuard.sol";

contract MockVote is Season, Ownable, ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                                 Error
    //////////////////////////////////////////////////////////////*/    

    error Vote__EmptyIsGiven();
    error Vote__AlreadyCalculated();
    error Vote__Claimed();
    error Vote__VerifyFailed();
    error Vote__NotWinner();
    error Vote__transferFailed();
    error Vote__CandidateNotFound();
    error Vote__NotCalculatedYet();
    error Vote__CandidateFound();
    error Vote__metadataInvalid();
    error Vote__AlreadyPaid();
    error Vote__NeedMore();
    error Vote__ResultMismatched();

    /*//////////////////////////////////////////////////////////////
                             State Variable
    //////////////////////////////////////////////////////////////*/    

    address immutable private REGISTRY_CONTRACT_ADDRESS;

    /**
     * @notice this stores the total amount each candidate willing to gives
     *
     * half of the totalRewards will be given to all the voter who has
     * voted the winner candidate
     *
     * remainder:
     * 3/5 -> manager
     * 2/5 -> Registry contract
     *
     * In short:
     * 0.5 -> voter
     * 0.2 -> Registry contract
     * 0.3 -> manager (if funds exceeding totalRewards, manager keeps it)
     *
     */
    uint immutable private s_candidatesGift;
    uint private s_rewardPerUser;

    mapping(address _voter => bool claimed) private s_isClaimed;

    string[] private s_candidates; // index == voteeId, stores candidate metadata
    uint[] private s_voteResult; // index == s_candidates
    
    uint private s_WinnerId = type(uint).max; // winner id
    bool private s_feesPaid; // manager calls withdraw
    bytes32 private s_merkleRoot;

    /*//////////////////////////////////////////////////////////////
                              constructor
    //////////////////////////////////////////////////////////////*/    

    constructor(address registry, address _manager, uint candidateSupply) Ownable(_manager) {
        assembly {
            if lt(candidateSupply, 1000000000000000000) {
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

        require(registry != address(0), "Zero Address");
        REGISTRY_CONTRACT_ADDRESS = registry;

        s_candidatesGift = candidateSupply;
    }

    /*//////////////////////////////////////////////////////////////
                           Adding Candidates
    //////////////////////////////////////////////////////////////*/    

    function addCandidate(string memory _metadata) 
        external 
        onlyOwner 
        gettingReady 
    {
        if (bytes(_metadata).length <= 7) revert Vote__metadataInvalid();

        // Note:
        // possible DoS wont be high because candidates wont be that much
        bytes32 hashedMetadata = keccak256(abi.encodePacked(_metadata));
        for (uint i = 0; i < s_candidates.length; i++) {
            if (keccak256(abi.encodePacked(s_candidates[i])) == hashedMetadata) {
                revert Vote__CandidateFound();
            }
        }

        s_candidates.push(_metadata);
    }

    /*//////////////////////////////////////////////////////////////
                               Vote Ended
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice this function is called when the vote is ended
     * @notice all the voters and candidates detail will be arranged here from the frontend 
     *
     * @param _voteResult total votes for each candidate in an array
     * @param totalUsers total number of users who voted the winning candidate
     * @param WinnerId id of the winning candidate
     * @param _merkleRoot merkle root of the whole votes
     *
     */
    function StopVote(uint[] memory _voteResult, uint totalUsers, uint WinnerId, bytes32 _merkleRoot) 
        external 
        onlyOwner 
        inProgress 
    {
        if (totalUsers <= 0 || _merkleRoot == bytes32(0)) revert Vote__EmptyIsGiven();
        if (s_WinnerId == type(uint).max || s_merkleRoot != bytes32(0)) revert Vote__AlreadyCalculated();
        if (s_candidates.length != _voteResult.length) revert Vote__ResultMismatched();

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

        uint gift = s_candidatesGift;
        assembly {
            // s_rewardPerUser = (s_candidates.length * s_candidatesGift) / (2 * totalUsers);
            sstore(
                s_rewardPerUser.slot,
                div(mul(sload(s_candidates.slot), mload(gift)), mul(2, totalUsers))
            )
            // s_merkleRoot = _merkleRoot;
            sstore(
                s_merkleRoot.slot,
                _merkleRoot
            )
            // s_WinnerId = WinnerId;
            sstore(
                s_WinnerId.slot,
                WinnerId
            )

            // s_voteResult = _voteResult;
            let slot := s_voteResult.slot
            let len := mload(_voteResult)
            sstore(slot, len)

            let dataOffset := add(_voteResult, 0x20)
            let hash := keccak256(slot, 0x20)

            for { let i := 0 } lt (i, len) { i := add(i, 1) } {
                let value := mload(add(dataOffset, mul(i, 0x20)))
                sstore(add(hash, i), value)      
            }

        }

        _incState();
        _helpIncState();
    }

    /*//////////////////////////////////////////////////////////////
                             Claim Rewards
    //////////////////////////////////////////////////////////////*/    

    function claim(uint candidateId, bytes32[] calldata proof) 
        external 
        finished 
        noReentrant // @audit wont hit, but just in case
    {
        if (s_isClaimed[msg.sender]) revert Vote__Claimed();
        if (candidateId != s_WinnerId) revert Vote__NotWinner();

        // Note: verify user
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, candidateId));
        bool Exist = MerkleProof.verifyCalldata(proof, s_merkleRoot, leaf);
        if (!Exist) revert Vote__VerifyFailed();

        s_isClaimed[msg.sender] = true;

        (bool ok, ) = msg.sender.call{value: s_rewardPerUser}("");
        if (!ok) revert Vote__transferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                               Withdrawal
    //////////////////////////////////////////////////////////////*/ 

    function withdraw() 
        external 
        onlyOwner 
        finished 
        noReentrant // @audit wont hit, but just in case
    {
        if (s_feesPaid) revert Vote__AlreadyPaid();
        s_feesPaid = true;

        uint bal = s_candidatesGift; // (s_candidatesGift * s_candidates.length) / 2;
        uint amountForRegistry; // (bal * 3) / 10;
        assembly {
            bal := div(mul(bal, sload(s_candidates.slot)), 2)
            amountForRegistry := div(mul(bal, 3), 10)
        }

        // Note: registry
        (bool ok, ) = REGISTRY_CONTRACT_ADDRESS.call{value: amountForRegistry}("");
        if (!ok) revert Vote__transferFailed();

        // Note: manager
        (ok, ) = msg.sender.call{value: bal - amountForRegistry}("");
        if (!ok) revert Vote__transferFailed();
    } 

    /*//////////////////////////////////////////////////////////////
                                Internal
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice straight away close the voting event if all the funds 
     * @notice by candidate has been collected 
     *
     */
    function _helpIncState() internal {
        // if (
        //     address(this).balance >= (s_candidates.length * s_candidatesGift) &&
        //     getCurrentState == state.Calculating
        // ) { _incState(); }

        uint balFunds = s_candidatesGift;
        assembly {
            balFunds := mul(
                sload(s_candidates.slot), 
                balFunds
            )
        }

        if (
            address(this).balance >= balFunds &&
            uint(getCurrentState()) == 2 // state.Calculating
        ) { _incState(); }

    }  

    /**
     * @notice help check the total msg.value sent
     * @param _amount the amount of funds sent (msg.value)
     *
     */
    function _fundSent(uint _amount) internal view {
        if (_amount < s_candidatesGift) revert Vote__NeedMore();
    }  

    /*//////////////////////////////////////////////////////////////
                                 Getter
    //////////////////////////////////////////////////////////////*/

    function getRegistryAddress() external view returns (address) {
        return REGISTRY_CONTRACT_ADDRESS;
    }
    function getTotalPoolRewards() external view returns(uint) {
        return (s_candidates.length * s_candidatesGift) / 2;
    }
    function getRewardPerUser() external view returns(uint) {
        return s_rewardPerUser;
    }
    function getCandidateMetadata(uint voteeId) external view returns (string memory) {
        return s_candidates[voteeId];
    }
    function getVoteResult(uint voteeId) external view returns (uint) {
        return s_voteResult[voteeId];
    }
    function getWinner() external view returns(string memory) {
        return s_candidates[s_WinnerId];
    }
    function isFeesPaidByManagerDone() external view returns(bool) {
        return s_feesPaid;
    }
    function getMerkleRoot() external view returns(bytes32) {
        return s_merkleRoot;
    }
    // function getCurrentState() external view returns (uint) { 
    //     return s_currentState.state; 
    // }    

    /*//////////////////////////////////////////////////////////////
                           Fallback & Receive
    //////////////////////////////////////////////////////////////*/

    receive() external payable { _fundSent(msg.value); _helpIncState(); }    
    fallback() external payable { _fundSent(msg.value); _helpIncState(); }


}