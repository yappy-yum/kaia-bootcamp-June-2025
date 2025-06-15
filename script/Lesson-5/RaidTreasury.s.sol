// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { RaidTreasury } from "../../src/Lesson-5/RaidTreasury.sol";
import { NetworkConfig } from "../NetworkConfig.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract RaidTreasuryS is Script {

    address Owner = makeAddr("Owner");

    RaidTreasury RT;
    ERC20Mock Gold;

    function run() public returns(RaidTreasury, ERC20Mock) {

        new NetworkConfig();

        _deployGold();
        _deployRaidTreasury();

        vm.startBroadcast();
        Gold.mint(address(RT), 20 ether);
        vm.stopBroadcast();

        return (RT, Gold);

    }

    function _deployRaidTreasury() private {

        vm.startBroadcast(Owner);
        RT = new RaidTreasury(address(Gold));
        vm.stopBroadcast();

    }

    function _deployGold() private {

        vm.startBroadcast(Owner);
        Gold = new ERC20Mock();
        vm.stopBroadcast();

    }

}   