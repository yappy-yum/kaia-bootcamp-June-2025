// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "./Utils/Ownable.sol";
import { Vote } from "./Vote.sol";

contract Registry is Ownable(msg.sender) {

    /*//////////////////////////////////////////////////////////////
                                 Error
    //////////////////////////////////////////////////////////////*/    

    error Registry__notManager();
    error Registry__ManagerGranded();
    error Registry__transferFailed();

    /*//////////////////////////////////////////////////////////////
                            state variables
    //////////////////////////////////////////////////////////////*/    
    
    struct VoteDetails {
        address manager;
        address contAddr;
    }
    VoteDetails[] private s_VoteAddress;
    mapping(address userAddr => bool _manager) private s_isManager;

    /*//////////////////////////////////////////////////////////////
                          Deploy Vote Contract
    //////////////////////////////////////////////////////////////*/    

    function CreateVote(uint supply) external {
        if (!s_isManager[msg.sender]) revert Registry__notManager();

        bytes memory bytesCode = abi.encodePacked(
            type(Vote).creationCode,
            abi.encode(msg.sender, supply)
        );
        bytes32 salt = bytes32(s_VoteAddress.length);

        address VoteAddr;
        assembly {
            VoteAddr := create2 (
                            0,
                            add(bytesCode, 32),
                            mload(bytesCode),
                            salt
                        )
        }

        s_VoteAddress.push(VoteDetails(
            msg.sender,
            VoteAddr
        ));
    } 

    /*//////////////////////////////////////////////////////////////
                             Grand Manager
    //////////////////////////////////////////////////////////////*/    

    function grandManager(address _managerToGrand) external onlyOwner {
        if (s_isManager[_managerToGrand]) revert Registry__ManagerGranded();
        s_isManager[_managerToGrand] = true;
    }

    /*//////////////////////////////////////////////////////////////
                             Owner Withdraw
    //////////////////////////////////////////////////////////////*/

    function withdraw() external onlyOwner {
        (bool ok, ) = msg.sender.call{value: address(this).balance}("");
        if (!ok) revert Registry__transferFailed();
    }    

    receive() external payable {}

}