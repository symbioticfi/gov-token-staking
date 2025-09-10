// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "lib/forge-std/src/Script.sol";

import {DeployNetworkForVaultsBase} from "@symbioticfi/network/script/base/DeployNetworkForVaultsBase.sol";
import {DeployNetworkBase} from "@symbioticfi/network/script/base/DeployNetworkBase.sol";

import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {NetworkRestakeDelegator} from "@symbioticfi/core/src/contracts/delegator/NetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IOperatorSpecificDelegator} from "@symbioticfi/core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IOperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/interfaces/delegator/IOperatorNetworkSpecificDelegator.sol";
import {DeployVaultBase} from "@symbioticfi/core/script/base/DeployVaultBase.sol";
import {IVaultConfigurator} from "@symbioticfi/core/src/interfaces/IVaultConfigurator.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IOperatorSpecificDelegator} from "@symbioticfi/core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IOperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/interfaces/delegator/IOperatorNetworkSpecificDelegator.sol";
import {IBaseSlasher} from "@symbioticfi/core/src/interfaces/slasher/IBaseSlasher.sol";
import {ISlasher} from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";
import {IVetoSlasher} from "@symbioticfi/core/src/interfaces/slasher/IVetoSlasher.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";
import {Vault} from "@symbioticfi/core/src/contracts/vault/Vault.sol";
import {FullRestakeDelegator} from "@symbioticfi/core/src/contracts/delegator/FullRestakeDelegator.sol";
import {OperatorSpecificDelegator} from "@symbioticfi/core/src/contracts/delegator/OperatorSpecificDelegator.sol";
import {OperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/contracts/delegator/OperatorNetworkSpecificDelegator.sol";

/**
 * @title DeployNetworkAndVault
 * @notice Comprehensive deployment script that deploys both a vault and network
 * @dev This script combines VaultBase and DeployNetworkForVaultsBase to create
 *      a complete deployment solution for the Symbiotic protocol
 */
contract DeployNetworkAndVault is Script {
    using Subnetwork for address;

    // AccessControl role constants
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    // ============ VAULT CONFIGURATION ============

    // Vault Configurator address (must be deployed beforehand)
    address public VAULT_CONFIGURATOR = 0x0000000000000000000000000000000000000000;

    // Vault owner address
    address public VAULT_OWNER = 0x0000000000000000000000000000000000000000;

    // Collateral token address
    address public COLLATERAL = 0x0000000000000000000000000000000000000000;

    // Burner address (can be zero address if no burning is needed)
    address public BURNER = 0x0000000000000000000000000000000000000000;

    // Epoch duration in seconds
    uint48 public EPOCH_DURATION = 7 days;

    // Whitelisted depositors (empty array means no whitelist)
    address[] public WHITELISTED_DEPOSITORS = new address[](0);

    // Deposit limit (0 means no limit)
    uint256 public DEPOSIT_LIMIT = 0;

    // Delegator type: 0=NetworkRestake, 1=FullRestake, 2=OperatorSpecific, 3=OperatorNetworkSpecific
    uint64 public DELEGATOR_INDEX = 0;

    // Hook address (can be zero address if no hook is needed)
    address public HOOK = 0x0000000000000000000000000000000000000000;

    // Whether to deploy with slasher
    bool public WITH_SLASHER = true;

    // Slasher type: 0=Slasher, 1=VetoSlasher
    uint64 public SLASHER_INDEX = 1;

    // Veto duration for VetoSlasher (only used if SLASHER_INDEX = 1)
    uint48 public VETO_DURATION = 3 days;

    // Network limit
    uint256 public NETWORK_LIMIT = 1_000_000 ether;

    // Operator network limit for FullRestakeDelegator
    uint256 public OPERATOR_NETWORK_LIMIT = 100_000 ether;

    // operators for NetworkRestakeDelegator and FullRestakeDelegator
    address[] public OPERATORS = new address[](0);

    // opertator shares for NetworkRestakeDelegator
    uint256 public OPERATOR_SHARE = 1e18;

    // delay in epochs for a network to update a resolver
    uint48 public RESOLVER_SET_EPOCHS_DELAY = 3;

    // allocation setters for NetworkRestakeDelegator and FullRestakeDelegator
    address[] public NETWORK_ALLOCATION_SETTERS = [0x0000000000000000000000000000000000000000];

    // allocation setters for FullRestakeDelegator
    address[] public OPERATOR_ALLOCATION_SETTERS = [0x0000000000000000000000000000000000000000];

    // ============ NETWORK CONFIGURATION ============

    // Network name
    string public NETWORK_NAME = "My Symbiotic Network";

    // Network metadata URI
    string public METADATA_URI = "https://example.com/metadata";

    // Network admin address (will become executor, proposer, and default admin)
    address public NETWORK_ADMIN = 0x0000000000000000000000000000000000000000;

    // Default minimum delay for network actions
    uint256 public DEFAULT_MIN_DELAY = 3 days;

    // Cold actions delay (upgrade proxy, set middleware)
    uint256 public COLD_ACTIONS_DELAY = 14 days;

    // Hot actions delay (set max network limit, set resolver)
    uint256 public HOT_ACTIONS_DELAY = 0;

    // Maximum network limit
    uint256 public MAX_NETWORK_LIMIT = 1_000_000 ether;

    // Resolver addresses (optional, for VetoSlasher)
    address public RESOLVER = address(0);

    // Subnetwork identifier
    uint96 public SUBNETWORK_ID = 0;

    // Salt for deterministic deployment
    bytes11 public SALT = "SymNetwork";

    function run() public {
        (
            address network,
            DeployNetworkBase.DeployNetworkParams memory deployNetworkParams,
            DeployNetworkBase.DeployNetworkParams memory updatedDeployNetworkParams
        ) = _deployNetwork();
        (address vault, address delegator,) = _deployVault(network);
        _updateNetworkParams(network, vault, deployNetworkParams, updatedDeployNetworkParams);
        _updateDelegatorParams(network, delegator);
        _transferVaultOwnership(vault, delegator);

        console2.log("Deployment completed successfully!");
        console2.log("Vault address:", vault);
        console2.log("Network address:", network);
    }

    function _deployVault(
        address network
    ) internal returns (address, address, address) {
        console2.log("Deploying vault...");
        // set temporarily the deployer as the vault owner
        (,, address deployer) = vm.readCallers();

        if (DELEGATOR_INDEX == 3) {
            NETWORK_ALLOCATION_SETTERS.push(network);
        }

        DeployVaultBase.DeployVaultParams memory deployVaultParams = DeployVaultBase.DeployVaultParams({
            owner: deployer,
            vaultParams: DeployVaultBase.VaultParams({
                baseParams: IVault.InitParams({
                    collateral: COLLATERAL,
                    burner: BURNER,
                    epochDuration: EPOCH_DURATION,
                    depositWhitelist: WHITELISTED_DEPOSITORS.length > 0,
                    isDepositLimit: DEPOSIT_LIMIT > 0,
                    depositLimit: DEPOSIT_LIMIT,
                    defaultAdminRoleHolder: deployer,
                    depositWhitelistSetRoleHolder: deployer,
                    depositorWhitelistRoleHolder: deployer,
                    isDepositLimitSetRoleHolder: deployer,
                    depositLimitSetRoleHolder: deployer
                }),
                whitelistedDepositors: WHITELISTED_DEPOSITORS
            }),
            delegatorIndex: DELEGATOR_INDEX,
            delegatorParams: DeployVaultBase.DelegatorParams({
                baseParams: IBaseDelegator.BaseParams({
                    defaultAdminRoleHolder: deployer,
                    hook: HOOK,
                    hookSetRoleHolder: deployer
                }),
                networkAllocationSettersOrNetwork: NETWORK_ALLOCATION_SETTERS,
                operatorAllocationSettersOrOperator: OPERATOR_ALLOCATION_SETTERS
            }),
            withSlasher: WITH_SLASHER,
            slasherIndex: SLASHER_INDEX,
            slasherParams: DeployVaultBase.SlasherParams({
                baseParams: IBaseSlasher.BaseParams({isBurnerHook: false}),
                vetoDuration: VETO_DURATION,
                resolverSetEpochsDelay: RESOLVER_SET_EPOCHS_DELAY
            })
        });

        DeployVaultBase vaultDeployer = new DeployVaultBase(deployVaultParams);
        return vaultDeployer.run();
    }

    function _deployNetwork()
        internal
        returns (address, DeployNetworkBase.DeployNetworkParams memory, DeployNetworkBase.DeployNetworkParams memory)
    {
        console2.log("Deploying network...");
        address[] memory proposers = new address[](1);
        proposers[0] = NETWORK_ADMIN;
        address[] memory executors = new address[](1);
        executors[0] = NETWORK_ADMIN;

        DeployNetworkBase.DeployNetworkParams memory deployNetworkParams = DeployNetworkBase.DeployNetworkParams({
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
        });
        DeployNetworkForVaultsBase deployNetworkForVaultsBase = new DeployNetworkForVaultsBase();
        DeployNetworkBase.DeployNetworkParams memory updatedDeployNetworkParams =
            deployNetworkForVaultsBase.updateDeployParamsForDeployer(deployNetworkParams);

        DeployNetworkBase deployNetworkBase = new DeployNetworkBase();
        address network = deployNetworkBase.run(updatedDeployNetworkParams);
        return (network, deployNetworkParams, updatedDeployNetworkParams);
    }

    function _updateNetworkParams(
        address network,
        address vault,
        DeployNetworkBase.DeployNetworkParams memory deployNetworkParams,
        DeployNetworkBase.DeployNetworkParams memory updatedDeployNetworkParams
    ) internal {
        DeployNetworkForVaultsBase deployNetworkForVaultsBase = new DeployNetworkForVaultsBase();

        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        uint256[] memory maxNetworkLimits = new uint256[](1);
        maxNetworkLimits[0] = MAX_NETWORK_LIMIT;
        address[] memory resolvers = new address[](1);
        resolvers[0] = RESOLVER;

        DeployNetworkForVaultsBase.DeployNetworkForVaultsParams memory deployNetworkForVaultsParams =
        DeployNetworkForVaultsBase.DeployNetworkForVaultsParams({
            deployNetworkParams: deployNetworkParams,
            vaults: vaults,
            maxNetworkLimits: maxNetworkLimits,
            resolvers: resolvers,
            subnetworkId: SUBNETWORK_ID
        });
        deployNetworkForVaultsBase.updateNetworkForVaults(
            network, deployNetworkForVaultsParams, updatedDeployNetworkParams
        );
    }

    function _updateDelegatorParams(address network, address delegator) internal {
        vm.startBroadcast();
        bytes32 subnetwork = address(network).subnetwork(SUBNETWORK_ID);
        if (DELEGATOR_INDEX == 0) {
            INetworkRestakeDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
            for (uint256 i = 0; i < OPERATORS.length; i++) {
                INetworkRestakeDelegator(delegator).setOperatorNetworkShares(subnetwork, OPERATORS[i], OPERATOR_SHARE);
            }
        } else if (DELEGATOR_INDEX == 1) {
            IFullRestakeDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
            for (uint256 i = 0; i < OPERATORS.length; i++) {
                IFullRestakeDelegator(delegator).setOperatorNetworkLimit(
                    subnetwork, OPERATORS[i], OPERATOR_NETWORK_LIMIT
                );
            }
        } else if (DELEGATOR_INDEX == 2) {
            IOperatorSpecificDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
        }
        vm.stopBroadcast();
    }

    function _transferVaultOwnership(address vault, address delegator) internal {
        vm.startBroadcast();

        (,, address oldAdmin) = vm.readCallers();

        Vault(vault).grantRole(Vault(vault).DEFAULT_ADMIN_ROLE(), VAULT_OWNER);
        Vault(vault).grantRole(Vault(vault).DEPOSIT_LIMIT_SET_ROLE(), VAULT_OWNER);
        Vault(vault).grantRole(Vault(vault).IS_DEPOSIT_LIMIT_SET_ROLE(), VAULT_OWNER);

        Vault(vault).renounceRole(Vault(vault).DEFAULT_ADMIN_ROLE(), oldAdmin);
        Vault(vault).renounceRole(Vault(vault).DEPOSIT_LIMIT_SET_ROLE(), oldAdmin);
        Vault(vault).renounceRole(Vault(vault).IS_DEPOSIT_LIMIT_SET_ROLE(), oldAdmin);
        Vault(vault).renounceRole(Vault(vault).DEPOSIT_WHITELIST_SET_ROLE(), oldAdmin);
        Vault(vault).renounceRole(Vault(vault).DEPOSITOR_WHITELIST_ROLE(), oldAdmin);

        assert(Vault(vault).hasRole(Vault(vault).DEFAULT_ADMIN_ROLE(), VAULT_OWNER) == true);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSIT_LIMIT_SET_ROLE(), VAULT_OWNER) == true);
        assert(Vault(vault).hasRole(Vault(vault).IS_DEPOSIT_LIMIT_SET_ROLE(), VAULT_OWNER) == true);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSIT_WHITELIST_SET_ROLE(), VAULT_OWNER) == false);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSITOR_WHITELIST_ROLE(), VAULT_OWNER) == false);

        assert(Vault(vault).hasRole(Vault(vault).DEFAULT_ADMIN_ROLE(), oldAdmin) == false);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSIT_LIMIT_SET_ROLE(), oldAdmin) == false);
        assert(Vault(vault).hasRole(Vault(vault).IS_DEPOSIT_LIMIT_SET_ROLE(), oldAdmin) == false);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSIT_WHITELIST_SET_ROLE(), oldAdmin) == false);
        assert(Vault(vault).hasRole(Vault(vault).DEPOSITOR_WHITELIST_ROLE(), oldAdmin) == false);

        assert(Vault(vault).owner() == address(0));

        if (DELEGATOR_INDEX == 0) {
            NetworkRestakeDelegator(delegator).grantRole(
                NetworkRestakeDelegator(delegator).DEFAULT_ADMIN_ROLE(), VAULT_OWNER
            );
            NetworkRestakeDelegator(delegator).grantRole(
                NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
            );
            NetworkRestakeDelegator(delegator).grantRole(
                NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_OWNER
            );

            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).DEFAULT_ADMIN_ROLE(), oldAdmin
            );
            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
            );
            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), oldAdmin
            );
            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).HOOK_SET_ROLE(), oldAdmin
            );

            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).DEFAULT_ADMIN_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).HOOK_SET_ROLE(), VAULT_OWNER
                ) == false
            );

            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).DEFAULT_ADMIN_ROLE(), oldAdmin
                ) == false
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
                ) == false
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), oldAdmin
                ) == false
            );
            assert(
                NetworkRestakeDelegator(delegator).hasRole(NetworkRestakeDelegator(delegator).HOOK_SET_ROLE(), oldAdmin)
                    == false
            );
        } else if (DELEGATOR_INDEX == 1) {
            FullRestakeDelegator(delegator).grantRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER);
            FullRestakeDelegator(delegator).grantRole(
                FullRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
            );
            FullRestakeDelegator(delegator).grantRole(
                FullRestakeDelegator(delegator).OPERATOR_NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
            );

            FullRestakeDelegator(delegator).renounceRole(DEFAULT_ADMIN_ROLE, oldAdmin);
            FullRestakeDelegator(delegator).renounceRole(
                FullRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
            );
            FullRestakeDelegator(delegator).renounceRole(
                FullRestakeDelegator(delegator).OPERATOR_NETWORK_LIMIT_SET_ROLE(), oldAdmin
            );
            FullRestakeDelegator(delegator).renounceRole(FullRestakeDelegator(delegator).HOOK_SET_ROLE(), oldAdmin);

            assert(FullRestakeDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER) == true);
            assert(
                FullRestakeDelegator(delegator).hasRole(
                    FullRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                FullRestakeDelegator(delegator).hasRole(
                    FullRestakeDelegator(delegator).OPERATOR_NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                FullRestakeDelegator(delegator).hasRole(FullRestakeDelegator(delegator).HOOK_SET_ROLE(), VAULT_OWNER)
                    == false
            );

            assert(FullRestakeDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, oldAdmin) == false);
            assert(
                FullRestakeDelegator(delegator).hasRole(
                    FullRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
                ) == false
            );
            assert(
                FullRestakeDelegator(delegator).hasRole(
                    FullRestakeDelegator(delegator).OPERATOR_NETWORK_LIMIT_SET_ROLE(), oldAdmin
                ) == false
            );
            assert(
                FullRestakeDelegator(delegator).hasRole(FullRestakeDelegator(delegator).HOOK_SET_ROLE(), oldAdmin)
                    == false
            );
        } else if (DELEGATOR_INDEX == 2) {
            OperatorSpecificDelegator(delegator).grantRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER);
            OperatorSpecificDelegator(delegator).grantRole(
                OperatorSpecificDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
            );

            OperatorSpecificDelegator(delegator).renounceRole(DEFAULT_ADMIN_ROLE, oldAdmin);
            OperatorSpecificDelegator(delegator).renounceRole(
                OperatorSpecificDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
            );
            OperatorSpecificDelegator(delegator).renounceRole(
                OperatorSpecificDelegator(delegator).HOOK_SET_ROLE(), oldAdmin
            );

            assert(OperatorSpecificDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER) == true);
            assert(
                OperatorSpecificDelegator(delegator).hasRole(
                    OperatorSpecificDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), VAULT_OWNER
                ) == true
            );
            assert(
                OperatorSpecificDelegator(delegator).hasRole(
                    OperatorSpecificDelegator(delegator).HOOK_SET_ROLE(), VAULT_OWNER
                ) == false
            );

            assert(OperatorSpecificDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, oldAdmin) == false);
            assert(
                OperatorSpecificDelegator(delegator).hasRole(
                    OperatorSpecificDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), oldAdmin
                ) == false
            );
            assert(
                OperatorSpecificDelegator(delegator).hasRole(
                    OperatorSpecificDelegator(delegator).HOOK_SET_ROLE(), oldAdmin
                ) == false
            );
        } else if (DELEGATOR_INDEX == 3) {
            OperatorNetworkSpecificDelegator(delegator).grantRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER);

            OperatorNetworkSpecificDelegator(delegator).renounceRole(DEFAULT_ADMIN_ROLE, oldAdmin);
            OperatorNetworkSpecificDelegator(delegator).renounceRole(
                OperatorNetworkSpecificDelegator(delegator).HOOK_SET_ROLE(), oldAdmin
            );

            assert(OperatorNetworkSpecificDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, VAULT_OWNER) == true);
            assert(
                OperatorNetworkSpecificDelegator(delegator).hasRole(
                    OperatorNetworkSpecificDelegator(delegator).HOOK_SET_ROLE(), VAULT_OWNER
                ) == false
            );

            assert(OperatorNetworkSpecificDelegator(delegator).hasRole(DEFAULT_ADMIN_ROLE, oldAdmin) == false);
            assert(
                OperatorNetworkSpecificDelegator(delegator).hasRole(
                    OperatorNetworkSpecificDelegator(delegator).HOOK_SET_ROLE(), oldAdmin
                ) == false
            );
        }

        vm.stopBroadcast();
    }
}
