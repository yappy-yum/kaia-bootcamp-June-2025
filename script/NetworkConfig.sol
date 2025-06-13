// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script, console } from "forge-std/Script.sol";

abstract contract MAGIC_NUMBER {

    uint KAIA_MAINNET_CHAIN_ID = 8217;
    uint KAIA_TESTNET_CHAIN_ID = 1001;
    uint ANVIL_CHAIN_ID = 31337;

}

contract NetworkConfig is MAGIC_NUMBER, Script {

    constructor() {

        vm.startBroadcast();

        if (msg.chainid == KAIA_MAINNET_CHAIN_ID) {
            console.log("Deploying to KAIA Mainnet ... ");

        } else if (msg.chainid == KAIA_TESTNET_CHAIN_ID) {
            console.log("Deploying to KAIA Testnet ... ");

        } else if (msg.chainid == ANVIL_CHAIN_ID) {
            console.log("Deploying to Anvil ... ");

        } else {
            revert("Unsupported network");
        }

        vm.stopBroadcast();

    }

}