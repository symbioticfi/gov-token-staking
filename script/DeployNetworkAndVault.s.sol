// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "lib/forge-std/src/Script.sol";

import {DeployNetworkForVaultsBase} from "@symbioticfi/network/script/base/DeployNetworkForVaultsBase.sol";
import {DeployNetworkBase} from "@symbioticfi/network/script/base/DeployNetworkBase.sol";

import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IOperatorSpecificDelegator} from "@symbioticfi/core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IOperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/interfaces/delegator/IOperatorNetworkSpecificDelegator.sol";
import {VaultBase} from "@symbioticfi/core/script/deploy/base/VaultBase.sol";
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

/**
 * @title DeployNetworkAndVault
 * @notice Comprehensive deployment script that deploys both a vault and network
 * @dev This script combines VaultBase and DeployNetworkForVaultsBase to create
 *      a complete deployment solution for the Symbiotic protocol
 */
contract DeployNetworkAndVault is Script {
        using Subnetwork for address;
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

    // Operator network limit
    uint256 public OPERATOR_NETWORK_LIMIT = 100_000 ether;

    // operators
    address[] public OPERATORS = new address[](0);

    // opertator shares
    uint256 public OPERATOR_SHARE = 1e18;

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

        console2.log("Deployment completed successfully!");
        console2.log("Vault address:", vault);
        console2.log("Network address:", network);
    }

    function _deployVault(
        address network
    ) internal returns (address, address, address) {
        console2.log("Deploying vault...");
        VaultBase.VaultParams memory vaultParams = VaultBase.VaultParams({
            vaultConfigurator: VAULT_CONFIGURATOR,
            owner: VAULT_OWNER,
            collateral: COLLATERAL,
            burner: BURNER,
            epochDuration: EPOCH_DURATION,
            whitelistedDepositors: WHITELISTED_DEPOSITORS,
            depositLimit: DEPOSIT_LIMIT,
            delegatorIndex: DELEGATOR_INDEX,
            hook: HOOK,
            network: network,
            withSlasher: WITH_SLASHER,
            slasherIndex: SLASHER_INDEX,
            vetoDuration: VETO_DURATION
        });

        VaultBase vaultDeployer = new VaultBase(vaultParams);
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

    function _updateDelegatorParams(
        address network,
        address delegator
    ) internal {
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
                IFullRestakeDelegator(delegator).setOperatorNetworkLimit(subnetwork, OPERATORS[i], OPERATOR_NETWORK_LIMIT);
            }
        } else if (DELEGATOR_INDEX == 2) {
            IOperatorSpecificDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
        } 
        vm.stopBroadcast();
    }
}
