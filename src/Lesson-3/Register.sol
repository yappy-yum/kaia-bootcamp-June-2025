// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {

    /*//////////////////////////////////////////////////////////////
                                 Event
    //////////////////////////////////////////////////////////////*/    

    event registered(
        string name,
        uint indexed studentCount,
        uint indexed year
    );

    /*//////////////////////////////////////////////////////////////
                             state variable
    //////////////////////////////////////////////////////////////*/

    struct setClass {
        string name; // student name
        uint studentCount; // number of students
        uint year; // year
    }    
    mapping(address _studentAddr => setClass _details) private s_studentDetails;

    /*//////////////////////////////////////////////////////////////
                                external
    //////////////////////////////////////////////////////////////*/

    function SetClass(string memory _name, uint _studentCount, uint _year) external {

        s_studentDetails[msg.sender] = setClass({
            name: _name,
            studentCount: _studentCount,
            year: _year
        });

        emit registered(_name, _studentCount, _year);

    }    

    /*//////////////////////////////////////////////////////////////
                                 Getter
    //////////////////////////////////////////////////////////////*/   

    function studentDetails(address _addr) public view returns (setClass memory) {
        return s_studentDetails[_addr];
    } 

}