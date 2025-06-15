// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { NetworkConfig } from "../NetworkConfig.sol"; 
import { Register } from "../../src/Lesson-3/Register.sol";

contract RegisterS is Script {

    address Owner = makeAddr("Owner");

    function run() public returns(Register) {

        new NetworkConfig();
        
        vm.startBroadcast(Owner);
        Register register = new Register();
        vm.stopBroadcast();

        return register;

    }

}