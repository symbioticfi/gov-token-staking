// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {DeployNetworkForVaultsBase} from "@symbioticfi/network/script/base/DeployNetworkForVaultsBase.sol";
import {DeployNetworkBase} from "@symbioticfi/network/script/base/DeployNetworkBase.sol";
import {SetMaxNetworkLimitBase} from "@symbioticfi/network/script/actions/base/SetMaxNetworkLimitBase.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {DeployVaultBase} from "@symbioticfi/core/script/base/DeployVaultBase.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

/**
 * @title DeployForCCIP
 * @notice Comprehensive deployment script that deploys both a vault and network
 *         Also, opt-ins the network to a second vault
 */
contract DeployForCCIP is Script {
    using Subnetwork for address;

    // ============ VAULT CONFIGURATION ============

    // Address of the owner of the vault who can migrate the vault to new versions whitelisted by Symbiotic
    address public VAULT_OWNER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; // TODO
    // Address of the collateral token
    address COLLATERAL = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    // Duration of the vault epoch (the withdrawal delay for staker varies from EPOCH_DURATION to 2 * EPOCH_DURATION depending on when the withdrawal is requested)
    uint48 EPOCH_DURATION = 7 days;
    // Who can adjust allocations for networks
    address[] NETWORK_LIMIT_SET_ROLE_HOLDERS = [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38]; // TODO
    // Who can adjust allocations for operators inside networks
    address[] OPERATOR_NETWORK_SHARES_SET_ROLE_HOLDERS = [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38]; // TODO
    // Operators addresses
    address[] OPERATORS = [0xe40C10408Eb0682B52510ad8C144fC13eC59d925]; // TODO
    // Operators shares
    uint256[] OPERATORS_SHARES = [1e18];

    // Optional

    // Deposit limit (maximum amount of the active stake allowed in the vault)
    uint256 DEPOSIT_LIMIT = 4_060_000 * 1e18; // TODO
    // Network limit
    uint256 public NETWORK_LIMIT = type(uint256).max;

    // ============ NETWORK CONFIGURATION ============

    // Network name
    string public NETWORK_NAME = "Lombard CCIP Network";
    // Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
    uint256 DEFAULT_MIN_DELAY = 3 days;
    // Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
    uint256 COLD_ACTIONS_DELAY = 21 days;
    // Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
    uint256 HOT_ACTIONS_DELAY = 0;
    // Admin address (will become executor, proposer, and default admin by default)
    address NETWORK_ADMIN = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; // TODO
    // Maximum amount of delegation that network is ready to receive
    uint256 MAX_NETWORK_LIMIT = type(uint256).max;

    // Optional

    // Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different resolvers for the same network)
    uint96 SUBNETWORK_ID = 0;
    // Metadata URI of the Network
    string METADATA_URI = "";
    // Salt for deterministic deployment
    bytes11 SALT = "LCCIPNet";

    // ============ SECOND VAULT OPT-IN CONFIGURATION ============

    address SECOND_VAULT = 0x7b276aAD6D2ebfD7e270C5a2697ac79182D9550E; // TODO
    uint256 SECOND_VAULT_MAX_NETWORK_LIMIT = 20_000_000 * 1e18;

    // ============ INTERNAL VARIABLES ============

    bool internal _isDeployerNetworkAllocationSetter;
    bool internal _isDeployerOperatorAllocationSetter;

    function run() public {
        (address vault, address delegator,) = _deployVault();
        address network = _deployNetwork(vault);
        _optInVaultToNetwork(network, delegator);

        console2.log("Deployment completed successfully!");
        console2.log("Vault address:", vault);
        console2.log("Network address:", network);

        _optInNetworkToSecondVault(network);

        console2.log("Opt-in to second vault completed successfully!");
    }

    function _deployVault() internal returns (address, address, address) {
        vm.startBroadcast();
        console2.log("Deploying vault...");
        (,, address deployer) = vm.readCallers();

        _isDeployerNetworkAllocationSetter = _contains(NETWORK_LIMIT_SET_ROLE_HOLDERS, deployer);
        if (!_isDeployerNetworkAllocationSetter) {
            NETWORK_LIMIT_SET_ROLE_HOLDERS.push(deployer);
        }

        _isDeployerOperatorAllocationSetter = _contains(OPERATOR_NETWORK_SHARES_SET_ROLE_HOLDERS, deployer);
        if (!_isDeployerOperatorAllocationSetter) {
            OPERATOR_NETWORK_SHARES_SET_ROLE_HOLDERS.push(deployer);
        }

        DeployVaultBase.SlasherParams memory emptySlasherParams;
        DeployVaultBase.DeployVaultParams memory deployVaultParams = DeployVaultBase.DeployVaultParams({
            owner: address(0),
            vaultParams: DeployVaultBase.VaultParams({
                baseParams: IVault.InitParams({
                    collateral: COLLATERAL,
                    burner: address(0),
                    epochDuration: EPOCH_DURATION,
                    depositWhitelist: false,
                    isDepositLimit: DEPOSIT_LIMIT > 0,
                    depositLimit: DEPOSIT_LIMIT,
                    defaultAdminRoleHolder: VAULT_OWNER,
                    depositWhitelistSetRoleHolder: address(0),
                    depositorWhitelistRoleHolder: address(0),
                    isDepositLimitSetRoleHolder: VAULT_OWNER,
                    depositLimitSetRoleHolder: VAULT_OWNER
                }),
                whitelistedDepositors: new address[](0)
            }),
            delegatorIndex: 0, // NetworkRestakeDelegator
            delegatorParams: DeployVaultBase.DelegatorParams({
                baseParams: IBaseDelegator.BaseParams({
                    defaultAdminRoleHolder: VAULT_OWNER,
                    hook: address(0),
                    hookSetRoleHolder: address(0)
                }),
                networkAllocationSettersOrNetwork: NETWORK_LIMIT_SET_ROLE_HOLDERS,
                operatorAllocationSettersOrOperator: OPERATOR_NETWORK_SHARES_SET_ROLE_HOLDERS
            }),
            withSlasher: false,
            slasherIndex: 0,
            slasherParams: emptySlasherParams
        });
        vm.stopBroadcast();
        DeployVaultBase vaultDeployer = new DeployVaultBase();
        return vaultDeployer.run(deployVaultParams);
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
        vm.stopBroadcast();
        DeployNetworkForVaultsBase deployNetworkForVaultsBase = new DeployNetworkForVaultsBase();
        return deployNetworkForVaultsBase.run(deployNetworkParams);
    }

    function _optInVaultToNetwork(address network, address delegator) internal {
        vm.startBroadcast();
        console2.log("Opting-in vault to network...");

        (,, address deployer) = vm.readCallers();

        bytes32 subnetwork = address(network).subnetwork(SUBNETWORK_ID);

        INetworkRestakeDelegator(delegator).setNetworkLimit(subnetwork, NETWORK_LIMIT);
        for (uint256 i; i < OPERATORS.length; ++i) {
            INetworkRestakeDelegator(delegator).setOperatorNetworkShares(subnetwork, OPERATORS[i], OPERATORS_SHARES[i]);
        }

        if (!_isDeployerNetworkAllocationSetter) {
            AccessControl(delegator).renounceRole(
                INetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), deployer
            );
        }
        if (!_isDeployerOperatorAllocationSetter) {
            AccessControl(delegator).renounceRole(
                INetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
            );
        }

        if (!_isDeployerNetworkAllocationSetter) {
            assert(
                AccessControl(delegator).hasRole(INetworkRestakeDelegator(delegator).NETWORK_LIMIT_SET_ROLE(), deployer)
                    == false
            );
        }
        if (!_isDeployerOperatorAllocationSetter) {
            assert(
                AccessControl(delegator).hasRole(
                    INetworkRestakeDelegator(delegator).OPERATOR_NETWORK_SHARES_SET_ROLE(), deployer
                ) == false
            );
        }
        vm.stopBroadcast();
    }

    function _optInNetworkToSecondVault(
        address network
    ) internal {
        SetMaxNetworkLimitBase setMaxNetworkLimitScheduler = new SetMaxNetworkLimitBase(
            SetMaxNetworkLimitBase.SetMaxNetworkLimitParams({
                network: network,
                vault: SECOND_VAULT,
                subnetworkId: SUBNETWORK_ID,
                maxNetworkLimit: SECOND_VAULT_MAX_NETWORK_LIMIT,
                delay: 0,
                salt: SALT
            })
        );
        setMaxNetworkLimitScheduler.runScheduleAndExecute();
    }

    function _contains(address[] memory array, address element) internal pure returns (bool) {
        for (uint256 i; i < array.length; ++i) {
            if (array[i] == element) {
                return true;
            }
        }
    }
}
