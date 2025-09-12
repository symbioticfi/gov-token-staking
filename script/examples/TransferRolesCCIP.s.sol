// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {Network} from "@symbioticfi/network/src/Network.sol";

contract TransferRolesCCIP is Script {
    address VAULT = 0x392F4B37C1Fe52D0c1A88C4C61218aD3d2A8a977; // TODO
    address VAULT_ADMIN = 0xD702F6Ba48CAb40607B6409aA07Fe9CFBc42364c;

    address payable NETWORK = payable(0xCe5677d5FB2BC7F501abB251DFbfB53DB3B2170b); // TODO
    address NETWORK_ADMIN = 0xD0AaD4982359E6A040751D0f9253C0a09000Caf8;

    function run() public {
        _transferVaultRoles();
        _transferNetworkRoles();
    }

    function _transferVaultRoles() internal {
        vm.startBroadcast();

        (,, address deployer) = vm.readCallers();

        AccessControl(VAULT).grantRole(AccessControl(VAULT).DEFAULT_ADMIN_ROLE(), VAULT_ADMIN);
        AccessControl(VAULT).grantRole(IVault(VAULT).DEPOSIT_LIMIT_SET_ROLE(), VAULT_ADMIN);
        AccessControl(VAULT).grantRole(IVault(VAULT).IS_DEPOSIT_LIMIT_SET_ROLE(), VAULT_ADMIN);

        AccessControl(VAULT).renounceRole(AccessControl(VAULT).DEFAULT_ADMIN_ROLE(), deployer);
        AccessControl(VAULT).renounceRole(IVault(VAULT).DEPOSIT_LIMIT_SET_ROLE(), deployer);
        AccessControl(VAULT).renounceRole(IVault(VAULT).IS_DEPOSIT_LIMIT_SET_ROLE(), deployer);
        AccessControl(VAULT).renounceRole(IVault(VAULT).DEPOSIT_WHITELIST_SET_ROLE(), deployer);
        AccessControl(VAULT).renounceRole(IVault(VAULT).DEPOSITOR_WHITELIST_ROLE(), deployer);

        address DELEGATOR = IVault(VAULT).delegator();

        AccessControl(DELEGATOR).grantRole(AccessControl(DELEGATOR).DEFAULT_ADMIN_ROLE(), VAULT_ADMIN);
        AccessControl(DELEGATOR).grantRole(INetworkRestakeDelegator(DELEGATOR).NETWORK_LIMIT_SET_ROLE(), VAULT_ADMIN);
        AccessControl(DELEGATOR).grantRole(
            INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_ADMIN
        );

        AccessControl(DELEGATOR).renounceRole(AccessControl(DELEGATOR).DEFAULT_ADMIN_ROLE(), deployer);
        AccessControl(DELEGATOR).renounceRole(INetworkRestakeDelegator(DELEGATOR).NETWORK_LIMIT_SET_ROLE(), deployer);
        AccessControl(DELEGATOR).renounceRole(
            INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
        );
        AccessControl(DELEGATOR).renounceRole(INetworkRestakeDelegator(DELEGATOR).HOOK_SET_ROLE(), deployer);

        assert(AccessControl(VAULT).hasRole(AccessControl(VAULT).DEFAULT_ADMIN_ROLE(), VAULT_ADMIN) == true);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSIT_LIMIT_SET_ROLE(), VAULT_ADMIN) == true);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).IS_DEPOSIT_LIMIT_SET_ROLE(), VAULT_ADMIN) == true);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSIT_WHITELIST_SET_ROLE(), VAULT_ADMIN) == false);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSITOR_WHITELIST_ROLE(), VAULT_ADMIN) == false);
        assert(AccessControl(DELEGATOR).hasRole(AccessControl(DELEGATOR).DEFAULT_ADMIN_ROLE(), VAULT_ADMIN) == true);
        assert(
            AccessControl(DELEGATOR).hasRole(INetworkRestakeDelegator(DELEGATOR).NETWORK_LIMIT_SET_ROLE(), VAULT_ADMIN)
                == true
        );
        assert(
            AccessControl(DELEGATOR).hasRole(
                INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_ADMIN
            ) == true
        );
        assert(
            AccessControl(DELEGATOR).hasRole(INetworkRestakeDelegator(DELEGATOR).HOOK_SET_ROLE(), VAULT_ADMIN) == false
        );

        assert(AccessControl(VAULT).hasRole(AccessControl(VAULT).DEFAULT_ADMIN_ROLE(), deployer) == false);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSIT_LIMIT_SET_ROLE(), deployer) == false);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).IS_DEPOSIT_LIMIT_SET_ROLE(), deployer) == false);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSIT_WHITELIST_SET_ROLE(), deployer) == false);
        assert(AccessControl(VAULT).hasRole(IVault(VAULT).DEPOSITOR_WHITELIST_ROLE(), deployer) == false);
        assert(AccessControl(DELEGATOR).hasRole(AccessControl(DELEGATOR).DEFAULT_ADMIN_ROLE(), deployer) == false);
        assert(
            AccessControl(DELEGATOR).hasRole(INetworkRestakeDelegator(DELEGATOR).NETWORK_LIMIT_SET_ROLE(), deployer)
                == false
        );
        assert(
            AccessControl(DELEGATOR).hasRole(
                INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
            ) == false
        );
        assert(AccessControl(DELEGATOR).hasRole(INetworkRestakeDelegator(DELEGATOR).HOOK_SET_ROLE(), deployer) == false);

        assert(Ownable(VAULT).owner() == address(0));

        vm.stopBroadcast();
    }

    function _transferNetworkRoles() internal {
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

        vm.stopBroadcast();
    }
}
