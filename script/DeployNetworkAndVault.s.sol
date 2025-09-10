// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "lib/forge-std/src/Script.sol";

import {DeployNetworkForVaultsBase} from "@symbioticfi/network/script/base/DeployNetworkForVaultsBase.sol";
import {DeployNetworkBase} from "@symbioticfi/network/script/base/DeployNetworkBase.sol";

import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {NetworkRestakeDelegator} from "@symbioticfi/core/src/contracts/delegator/NetworkRestakeDelegator.sol";
import {DeployVaultBase} from "@symbioticfi/core/script/base/DeployVaultBase.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {IBaseSlasher} from "@symbioticfi/core/src/interfaces/slasher/IBaseSlasher.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

/**
 * @title DeployNetworkAndVault
 * @notice Comprehensive deployment script that deploys both a vault and network
 * @dev This script combines VaultBase and DeployNetworkForVaultsBase to create
 *      a complete deployment solution for the Symbiotic protocol
 */
contract DeployNetworkAndVault is Script {
    using Subnetwork for address;

    // ============ VAULT CONFIGURATION ============

    // Vault owner address
    address public VAULT_OWNER = 0x0000000000000000000000000000000000000000;
    // Address of the collateral token
    address COLLATERAL = 0x0000000000000000000000000000000000000000;
    // Vault's burner to send slashed funds to (e.g., 0xdEaD or some unwrapper contract; not used in case of no slasher)
    address BURNER = 0x0000000000000000000000000000000000000000;
    // Duration of the vault epoch (the withdrawal delay for staker varies from EPOCH_DURATION to 2 * EPOCH_DURATION depending on when the withdrawal is requested)
    uint48 EPOCH_DURATION = 1 days;
    // Setting depending on the delegator type:
    // 0. NetworkLimitSetRoleHolders (adjust allocations for networks)
    // 1. NetworkLimitSetRoleHolders (adjust allocations for networks)
    // 2. NetworkLimitSetRoleHolders (adjust allocations for networks)
    // 3. network (the only network that will receive the stake; should be an array with a single element)
    address[] NETWORK_ALLOCATION_SETTERS_OR_NETWORK = [0x0000000000000000000000000000000000000000];
    // Setting depending on the delegator type:
    // 0. OperatorNetworkSharesSetRoleHolders (adjust allocations for operators inside networks; in shares, resulting percentage is operatorShares / totalOperatorShares)
    // 1. OperatorNetworkLimitSetRoleHolders (adjust allocations for operators inside networks; in shares, resulting percentage is operatorShares / totalOperatorShares)
    // 2. operator (the only operator that will receive the stake; should be an array with a single element)
    // 3. operator (the only operator that will receive the stake; should be an array with a single element)
    address[] OPERATOR_ALLOCATION_SETTERS_OR_OPERATOR = [0x0000000000000000000000000000000000000000];
    // Operator address
    address OPERATOR = 0x0000000000000000000000000000000000000000;
    // Whether to deploy a slasher
    bool WITH_SLASHER = false;
    // Type of the slasher:
    //  0. Slasher (allows instant slashing)
    //  1. VetoSlasher (allows having a veto period if the resolver is set)
    uint64 SLASHER_INDEX = 1;
    // Duration of a veto period (should be less than EPOCH_DURATION)
    uint48 VETO_DURATION = 1 days;

    // Optional

    // Deposit limit (maximum amount of the active stake allowed in the vault)
    uint256 DEPOSIT_LIMIT = 0;
    // Addresses of the whitelisted depositors
    address[] WHITELISTED_DEPOSITORS = new address[](0);
    // Address of the hook contract which, e.g., can automatically adjust the allocations on slashing events (not used in case of no slasher)
    address HOOK = 0x0000000000000000000000000000000000000000;
    // Delay in epochs for a network to update a resolver
    uint48 RESOLVER_SET_EPOCHS_DELAY = 3;
    // Network limit
    uint256 public NETWORK_LIMIT = type(uint256).max;
    // opertator shares for NetworkRestakeDelegator
    uint256 public OPERATOR_SHARE = 1e18;

    // ============ NETWORK CONFIGURATION ============

    // Network name
    string public NETWORK_NAME = "My Symbiotic Network";
    // Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
    uint256 DEFAULT_MIN_DELAY = 3 days;
    // Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
    uint256 COLD_ACTIONS_DELAY = 14 days;
    // Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
    uint256 HOT_ACTIONS_DELAY = 0;
    // Admin address (will become executor, proposer, and default admin by default)
    address NETWORK_ADMIN = 0x0000000000000000000000000000000000000000;
    // Maximum amount of delegation that network is ready to receive (multiple vaults can be set)
    uint256 MAX_NETWORK_LIMIT = 0;
    // Resolver address (optional, is applied only if VetoSlasher is used) (multiple vaults can be set)
    address RESOLVER = 0x0000000000000000000000000000000000000000;

    // Optional

    // Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different resolvers for the same network)
    uint96 SUBNETWORK_ID = 0;
    // Metadata URI of the Network
    string METADATA_URI = "";
    // Salt for deterministic deployment
    bytes11 SALT = "SymNetwork";

    // ============ INTERNAL VARIABLES ============

    bool internal _isDeployerNetworkAllocationSetter;
    bool internal _isDeployerOperatorAllocationSetter;

    function run() public {
        (address vault, address delegator,) = _deployVault();
        address network = _deployNetwork(vault);
        _updateDelegatorParams(network, delegator);
        _checkRoles(delegator);

        console2.log("Deployment completed successfully!");
        console2.log("Vault address:", vault);
        console2.log("Network address:", network);
    }

    function _deployVault() internal returns (address, address, address) {
        console2.log("Deploying vault...");
        (,, address deployer) = vm.readCallers();

        _isDeployerNetworkAllocationSetter = _contains(NETWORK_ALLOCATION_SETTERS_OR_NETWORK, deployer);
        if (!_isDeployerNetworkAllocationSetter) {
            NETWORK_ALLOCATION_SETTERS_OR_NETWORK.push(deployer);
        }

        _isDeployerOperatorAllocationSetter = _contains(OPERATOR_ALLOCATION_SETTERS_OR_OPERATOR, deployer);
        if (!_isDeployerOperatorAllocationSetter) {
            OPERATOR_ALLOCATION_SETTERS_OR_OPERATOR.push(deployer);
        }

        DeployVaultBase.DeployVaultParams memory deployVaultParams = DeployVaultBase.DeployVaultParams({
            owner: VAULT_OWNER,
            vaultParams: DeployVaultBase.VaultParams({
                baseParams: IVault.InitParams({
                    collateral: COLLATERAL,
                    burner: BURNER,
                    epochDuration: EPOCH_DURATION,
                    depositWhitelist: WHITELISTED_DEPOSITORS.length > 0,
                    isDepositLimit: DEPOSIT_LIMIT > 0,
                    depositLimit: DEPOSIT_LIMIT,
                    defaultAdminRoleHolder: VAULT_OWNER,
                    depositWhitelistSetRoleHolder: VAULT_OWNER,
                    depositorWhitelistRoleHolder: VAULT_OWNER,
                    isDepositLimitSetRoleHolder: VAULT_OWNER,
                    depositLimitSetRoleHolder: VAULT_OWNER
                }),
                whitelistedDepositors: WHITELISTED_DEPOSITORS
            }),
            delegatorIndex: 0, // NetworkRestakeDelegator
            delegatorParams: DeployVaultBase.DelegatorParams({
                baseParams: IBaseDelegator.BaseParams({
                    defaultAdminRoleHolder: VAULT_OWNER,
                    hook: HOOK,
                    hookSetRoleHolder: VAULT_OWNER
                }),
                networkAllocationSettersOrNetwork: NETWORK_ALLOCATION_SETTERS_OR_NETWORK,
                operatorAllocationSettersOrOperator: OPERATOR_ALLOCATION_SETTERS_OR_OPERATOR
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

    function _deployNetwork(
        address vault
    ) internal returns (address) {
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
        resolvers[0] = RESOLVER;

        DeployNetworkForVaultsBase.DeployNetworkForVaultsParams memory deployNetworkParams = DeployNetworkForVaultsBase
            .DeployNetworkForVaultsParams({
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

        DeployNetworkForVaultsBase deployNetworkForVaultsBase = new DeployNetworkForVaultsBase();

        return deployNetworkForVaultsBase.run(deployNetworkParams);
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
        (,, address deployer) = vm.readCallers();

        vm.startBroadcast();
        bytes32 subnetwork = address(network).subnetwork(SUBNETWORK_ID);

        INetworkRestakeDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
        INetworkRestakeDelegator(delegator).setOperatorNetworkShares(subnetwork, OPERATOR, OPERATOR_SHARE);

        if (!_isDeployerNetworkAllocationSetter) {
            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), deployer
            );
        }
        if (!_isDeployerOperatorAllocationSetter) {
            NetworkRestakeDelegator(delegator).renounceRole(
                NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
            );
        }

        vm.stopBroadcast();
    }

    function _checkRoles(
        address delegator
    ) internal {
        (,, address deployer) = vm.readCallers();
        if (!_isDeployerNetworkAllocationSetter) {
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), deployer
                ) == false
            );
        }
        if (!_isDeployerOperatorAllocationSetter) {
            assert(
                NetworkRestakeDelegator(delegator).hasRole(
                    NetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
                ) == false
            );
        }
    }

    function _contains(address[] memory array, address element) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }
}
