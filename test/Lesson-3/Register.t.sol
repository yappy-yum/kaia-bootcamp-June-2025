// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { Register } from "../../src/Lesson-3/Register.sol";
import { RegisterS } from "../../script/Lesson-3/Register.s.sol";

contract RegisterT is Test {

    Register R;

    address Bob = makeAddr("Bob");
    address Alice = makeAddr("Alice");

    /*//////////////////////////////////////////////////////////////
                                 setUp
    //////////////////////////////////////////////////////////////*/    

    function setUp() public {
        RegisterS _R = new RegisterS();
        R = _R.run();
    }

    /*//////////////////////////////////////////////////////////////
                               SetClass()
    //////////////////////////////////////////////////////////////*/    

    function test_SetClass() public {

        // Bob calls
        vm.expectEmit(true, true, false, true);
        emit Register.registered("Bob", 50, 2025);

        vm.prank(Bob);
        R.SetClass("Bob", 50, 2025);

        // Alice calls
        vm.expectEmit(true, true, false, true);
        emit Register.registered("Alice", 25, 2025);

        vm.prank(Alice);
        R.SetClass("Alice", 25, 2025);        

        // check Bob 
        assertEq(R.studentDetails(Bob).name, "Bob");
        assertEq(R.studentDetails(Bob).studentCount, 50);
        assertEq(R.studentDetails(Bob).year, 2025);

        // check Alice
        assertEq(R.studentDetails(Alice).name, "Alice");
        assertEq(R.studentDetails(Alice).studentCount, 25);
        assertEq(R.studentDetails(Alice).year, 2025);

    }

}