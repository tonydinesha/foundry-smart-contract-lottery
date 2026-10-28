// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig
            .getConfig();

        // create subscriptions
        if (activeNetworkConfig.subscriptionId == 0) {
            (uint256 subId, address vrfCoordinator) = new CreateSubscription()
                .createSubscription(
                    activeNetworkConfig.vrfCoordinator,
                    activeNetworkConfig.account
                );
            activeNetworkConfig.subscriptionId = subId;
            activeNetworkConfig.vrfCoordinator = vrfCoordinator;
        }

        //Fund subscription
        FundSubscription funder = new FundSubscription();
        funder.fundSubscription(
            activeNetworkConfig.vrfCoordinator,
            activeNetworkConfig.subscriptionId,
            activeNetworkConfig.link,
            activeNetworkConfig.account
        );

        vm.startBroadcast(activeNetworkConfig.account);
        Raffle raffle = new Raffle(
            activeNetworkConfig.entranceFee,
            activeNetworkConfig.interval,
            activeNetworkConfig.vrfCoordinator,
            activeNetworkConfig.keyHash,
            activeNetworkConfig.subscriptionId,
            activeNetworkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        // Add consumer
        AddConsumer consumerAdder = new AddConsumer();
        consumerAdder.addConsumer(
            address(raffle),
            activeNetworkConfig.vrfCoordinator,
            activeNetworkConfig.subscriptionId,
            activeNetworkConfig.account
        );
        return (raffle, helperConfig);
    }
}
