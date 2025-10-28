// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {Network} from "@symbioticfi/network/src/Network.sol";

contract TransferVaultRoles is Script {
    address VAULT = 0xD538A11e421449F2BAFA153F678C81E7a4f411B3;
    address VAULT_ADMIN = 0xD702F6Ba48CAb40607B6409aA07Fe9CFBc42364c;

    function run() public {
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
        AccessControl(DELEGATOR)
            .grantRole(INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_ADMIN);

        AccessControl(DELEGATOR).renounceRole(AccessControl(DELEGATOR).DEFAULT_ADMIN_ROLE(), deployer);
        AccessControl(DELEGATOR).renounceRole(INetworkRestakeDelegator(DELEGATOR).NETWORK_LIMIT_SET_ROLE(), deployer);
        AccessControl(DELEGATOR)
            .renounceRole(INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer);
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
            AccessControl(DELEGATOR)
                .hasRole(INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_ADMIN) == true
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
            AccessControl(DELEGATOR)
                .hasRole(INetworkRestakeDelegator(DELEGATOR).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer) == false
        );
        assert(AccessControl(DELEGATOR).hasRole(INetworkRestakeDelegator(DELEGATOR).HOOK_SET_ROLE(), deployer) == false);

        assert(Ownable(VAULT).owner() == address(0));

        console2.log("Vault roles transferred successfully!");

        vm.stopBroadcast();
    }
}
