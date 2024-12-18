// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingScript is Script {
    Crowdfunding public crowdfunding;

    function setUp() public {
        // Configurações iniciais, se necessário
    }

    function run() public {
        vm.startBroadcast();

        // Deploy do contrato Crowdfunding
        crowdfunding = new Crowdfunding();

        vm.stopBroadcast();
    }
}
