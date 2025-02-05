// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script} from "forge-std/Script.sol";
import {Helper} from "./Helper.s.sol";

contract UpgradeLLMOracleCoordinator is Script {
    Helper public helper;

    constructor() {
        helper = new Helper();
    }

    function run() public returns (address impl) {
        // todo: get proxy address
        address proxy = 0xe3Ab5D57Feb189d7CD1685336FD638856391b9EB;

        vm.startBroadcast();
        impl = upgrade(proxy);
        vm.stopBroadcast();

        helper.writeProxyAddresses("LLMOracleCoordinator", proxy, impl);
    }

    function upgrade(address proxy) public returns (address impl) {
        Upgrades.upgradeProxy(proxy, "LLMOracleCoordinatorV2.sol", "");
        impl = Upgrades.getImplementationAddress(proxy);
    }
}

contract UpgradeLLMOracleRegistry is Script {
    Helper public helper;

    constructor() {
        helper = new Helper();
    }

    function run() public returns (address impl) {
        // todo: get proxy address
        address proxy = 0x568Cfb5363E70Cde784f8603E2748e614c3420a7;

        vm.startBroadcast();
        impl = upgrade(proxy);
        vm.stopBroadcast();

        helper.writeProxyAddresses("LLMOracleRegistry", proxy, impl);
    }

    function upgrade(address proxy) public returns (address impl) {
        Upgrades.upgradeProxy(proxy, "LLMOracleRegistryV2.sol", "");
        impl = Upgrades.getImplementationAddress(proxy);
    }
}
