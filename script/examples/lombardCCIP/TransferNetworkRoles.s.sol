// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {Network} from "@symbioticfi/network/src/Network.sol";

contract TransferNetworkRoles is Script {
    address payable NETWORK = payable(0x769f653c1CD9f2abcBACBfeAaE5C9D8Dc2033Fef);
    address NETWORK_ADMIN = 0xD0AaD4982359E6A040751D0f9253C0a09000Caf8;

    function run() public {
        vm.startBroadcast();

        (,, address deployer) = vm.readCallers();

        Network(NETWORK).grantRole(Network(NETWORK).DEFAULT_ADMIN_ROLE(), NETWORK_ADMIN);
        Network(NETWORK).grantRole(Network(NETWORK).PROPOSER_ROLE(), NETWORK_ADMIN);
        Network(NETWORK).grantRole(Network(NETWORK).EXECUTOR_ROLE(), NETWORK_ADMIN);
        Network(NETWORK).grantRole(Network(NETWORK).CANCELLER_ROLE(), NETWORK_ADMIN);
        Network(NETWORK).grantRole(Network(NETWORK).NAME_UPDATE_ROLE(), NETWORK_ADMIN);
        Network(NETWORK).grantRole(Network(NETWORK).METADATA_URI_UPDATE_ROLE(), NETWORK_ADMIN);

        Network(NETWORK).renounceRole(Network(NETWORK).DEFAULT_ADMIN_ROLE(), deployer);
        Network(NETWORK).renounceRole(Network(NETWORK).PROPOSER_ROLE(), deployer);
        Network(NETWORK).renounceRole(Network(NETWORK).EXECUTOR_ROLE(), deployer);
        Network(NETWORK).renounceRole(Network(NETWORK).CANCELLER_ROLE(), deployer);
        Network(NETWORK).renounceRole(Network(NETWORK).NAME_UPDATE_ROLE(), deployer);
        Network(NETWORK).renounceRole(Network(NETWORK).METADATA_URI_UPDATE_ROLE(), deployer);

        assert(Network(NETWORK).hasRole(Network(NETWORK).DEFAULT_ADMIN_ROLE(), NETWORK_ADMIN) == true);
        assert(Network(NETWORK).hasRole(Network(NETWORK).PROPOSER_ROLE(), NETWORK_ADMIN) == true);
        assert(Network(NETWORK).hasRole(Network(NETWORK).EXECUTOR_ROLE(), NETWORK_ADMIN) == true);
        assert(Network(NETWORK).hasRole(Network(NETWORK).CANCELLER_ROLE(), NETWORK_ADMIN) == true);
        assert(Network(NETWORK).hasRole(Network(NETWORK).NAME_UPDATE_ROLE(), NETWORK_ADMIN) == true);
        assert(Network(NETWORK).hasRole(Network(NETWORK).METADATA_URI_UPDATE_ROLE(), NETWORK_ADMIN) == true);

        assert(Network(NETWORK).hasRole(Network(NETWORK).DEFAULT_ADMIN_ROLE(), deployer) == false);
        assert(Network(NETWORK).hasRole(Network(NETWORK).PROPOSER_ROLE(), deployer) == false);
        assert(Network(NETWORK).hasRole(Network(NETWORK).EXECUTOR_ROLE(), deployer) == false);
        assert(Network(NETWORK).hasRole(Network(NETWORK).CANCELLER_ROLE(), deployer) == false);
        assert(Network(NETWORK).hasRole(Network(NETWORK).NAME_UPDATE_ROLE(), deployer) == false);
        assert(Network(NETWORK).hasRole(Network(NETWORK).METADATA_URI_UPDATE_ROLE(), deployer) == false);

        console2.log("Network roles transferred successfully!");

        vm.stopBroadcast();
    }
}
