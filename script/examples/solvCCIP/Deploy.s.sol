// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {DeployNetworkForVaultsBase} from "@symbioticfi/network/script/base/DeployNetworkForVaultsBase.sol";
import {DeployNetworkBase} from "@symbioticfi/network/script/base/DeployNetworkBase.sol";

import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

/**
 * @title Deploy
 * @notice Comprehensive deployment script that deploys both a vault and network
 *         Also, opt-ins the network to a second vault
 */
contract Deploy is Script {
    using Subnetwork for address;

    // ============ NETWORK CONFIGURATION ============

    // Network name
    string public NETWORK_NAME = "Solv CCIP Network";
    // Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
    uint256 DEFAULT_MIN_DELAY = 0;
    // Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
    uint256 COLD_ACTIONS_DELAY = 0;
    // Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
    uint256 HOT_ACTIONS_DELAY = 0;
    // Admin address (will become executor, proposer, and default admin by default)
    address NETWORK_ADMIN = 0xFC6Ffb38CAf426D7Ae921d691c2C6Da65E6E3DcA;
    // Maximum amount of delegation that network is ready to receive
    uint256 MAX_NETWORK_LIMIT = type(uint256).max;
    // Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different resolvers for the same network)
    uint96 SUBNETWORK_ID = 0;
    // Metadata URI of the Network
    string METADATA_URI = "";
    // Salt for deterministic deployment
    bytes11 SALT = "SCCIPNet";

    address LINK_VAULT = 0xD538A11e421449F2BAFA153F678C81E7a4f411B3;

    function run() public {
        address network = _deployNetwork(LINK_VAULT);

        console2.log("Deployment completed successfully!");
        console2.log("Network address:", network);
    }

    function _deployNetwork(
        address vault
    ) internal returns (address) {
        vm.startBroadcast();
        console2.log("Deploying network...");
        address[] memory proposers = new address[](1);
        proposers[0] = NETWORK_ADMIN;
        address[] memory executors = new address[](1);
        executors[0] = NETWORK_ADMIN;
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        uint256[] memory maxNetworkLimits = new uint256[](1);
        maxNetworkLimits[0] = MAX_NETWORK_LIMIT;
        address[] memory resolvers = new address[](1);
        resolvers[0] = address(0);

        DeployNetworkForVaultsBase.DeployNetworkForVaultsParams memory deployNetworkParams =
            DeployNetworkForVaultsBase.DeployNetworkForVaultsParams({
                deployNetworkParams: DeployNetworkBase.DeployNetworkParams({
                    name: NETWORK_NAME,
                    metadataURI: METADATA_URI,
                    proposers: proposers,
                    executors: executors,
                    defaultAdminRoleHolder: NETWORK_ADMIN,
                    nameUpdateRoleHolder: NETWORK_ADMIN,
                    metadataURIUpdateRoleHolder: NETWORK_ADMIN,
                    globalMinDelay: DEFAULT_MIN_DELAY,
                    upgradeProxyMinDelay: COLD_ACTIONS_DELAY,
                    setMiddlewareMinDelay: COLD_ACTIONS_DELAY,
                    setMaxNetworkLimitMinDelay: HOT_ACTIONS_DELAY,
                    setResolverMinDelay: HOT_ACTIONS_DELAY,
                    salt: SALT
                }),
                vaults: vaults,
                maxNetworkLimits: maxNetworkLimits,
                resolvers: resolvers,
                subnetworkId: SUBNETWORK_ID
            });
        vm.stopBroadcast();
        DeployNetworkForVaultsBase deployNetworkForVaultsBase = new DeployNetworkForVaultsBase();
        return deployNetworkForVaultsBase.run(deployNetworkParams);
    }
}
