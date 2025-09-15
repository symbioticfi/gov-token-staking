// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {SetMaxNetworkLimitBase} from "@symbioticfi/network/script/actions/base/SetMaxNetworkLimitBase.sol";

contract OptIntoVault is Script {
    address NETWORK = 0x769f653c1CD9f2abcBACBfeAaE5C9D8Dc2033Fef;
    uint96 SUBNETWORK_ID = 0;
    bytes11 SALT = "LCCIPNet";

    address SECOND_VAULT = 0x7b276aAD6D2ebfD7e270C5a2697ac79182D9550E; // TODO
    uint256 SECOND_VAULT_MAX_NETWORK_LIMIT = 20_000_000 * 1e18;

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
