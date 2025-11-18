// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {SetMaxNetworkLimitBase} from "@symbioticfi/network/script/actions/base/SetMaxNetworkLimitBase.sol";

contract OptIntoVault is Script {
    address NETWORK = 0xf02D5A6aDEC0286be3e13886C9C2e782679B6c39;
    uint96 SUBNETWORK_ID = 0;
    bytes11 SALT = "SCCIPNet";

    address SECOND_VAULT = 0xD01f195f4D3033F25F1DEE614F0DCeD882dBBC56;
    uint256 SECOND_VAULT_MAX_NETWORK_LIMIT = type(uint256).max;

    function run() public {
        SetMaxNetworkLimitBase setMaxNetworkLimitScheduler = new SetMaxNetworkLimitBase(
            SetMaxNetworkLimitBase.SetMaxNetworkLimitParams({
                network: NETWORK,
                vault: SECOND_VAULT,
                subnetworkId: SUBNETWORK_ID,
                maxNetworkLimit: SECOND_VAULT_MAX_NETWORK_LIMIT,
                delay: 0,
                salt: SALT
            })
        );
        setMaxNetworkLimitScheduler.runScheduleAndExecute();

        console2.log("Opt-in to second vault completed successfully!");
    }
}
