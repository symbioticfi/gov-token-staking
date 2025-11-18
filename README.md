**[Symbiotic Protocol](https://symbiotic.fi) is an extremely flexible and permissionless shared security system.**

This repository contains a tooling that helps protocols' contributors to launch a staking program for their governance token.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/symbioticfi/gov-token-staking)

## Documentation

- [What is Symbiotic?](https://docs.symbiotic.fi/)

## Usage

### Dependencies

- Git ([installation](https://git-scm.com/downloads))
- foundry ([installation](https://getfoundry.sh/introduction/installation/))
- npm ([installation](https://nodejs.org/en/download/))

### Prerequisites

**Clone the repository**

```bash
git clone --recurse-submodules https://github.com/symbioticfi/gov-token-staking.git
```

### Deploy Your Governance Token Staking

Open [DeployGovTokenStaking.s.sol](./script/DeployGovTokenStaking.s.sol), you will see config like this:

```solidity
// ============ VAULT CONFIGURATION ============

// Address of the owner of the vault who can migrate the vault to new versions whitelisted by Symbiotic
address public VAULT_OWNER = 0x0000000000000000000000000000000000000000;
// Address of the collateral token
address COLLATERAL = 0x0000000000000000000000000000000000000000;
// Vault's burner to send slashed funds to (e.g., 0xdEaD or some unwrapper contract; not used in case of no slasher)
address BURNER = 0x000000000000000000000000000000000000dEaD;
// Duration of the vault epoch (the withdrawal delay for staker varies from EPOCH_DURATION to 2 * EPOCH_DURATION depending on when the withdrawal is requested)
uint48 EPOCH_DURATION = 7 days;
// Who can adjust allocations for networks
address[] NETWORK_LIMIT_SET_ROLE_HOLDERS = [0x0000000000000000000000000000000000000000];
// Who can adjust allocations for operators inside networks
address[] OPERATOR_NETWORK_SHARES_SET_ROLE_HOLDERS = [0x0000000000000000000000000000000000000000];
// Operators addresses
address[] OPERATORS = [0x0000000000000000000000000000000000000000];
// Operators shares
uint256[] OPERATORS_SHARES = [1e18];
// Whether to deploy a slasher
bool WITH_SLASHER = true;
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
// Network limit
uint256 public NETWORK_LIMIT = type(uint256).max;
// Address of the hook contract which, e.g., can automatically adjust the allocations on slashing events (not used in case of no slasher)
address HOOK = 0x0000000000000000000000000000000000000000;
// Delay in epochs for a network to update a resolver
uint48 RESOLVER_SET_EPOCHS_DELAY = 3;

// ============ NETWORK CONFIGURATION ============

// Network name
string public NETWORK_NAME = "My Network";
// Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
uint256 DEFAULT_MIN_DELAY = 3 days;
// Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
uint256 COLD_ACTIONS_DELAY = 14 days;
// Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
uint256 HOT_ACTIONS_DELAY = 0;
// Admin address (will become executor, proposer, and default admin by default)
address NETWORK_ADMIN = 0x0000000000000000000000000000000000000000;
// Maximum amount of delegation that network is ready to receive
uint256 MAX_NETWORK_LIMIT = type(uint256).max;
// Resolver address (optional, is applied only if VetoSlasher is used)
address RESOLVER = 0x0000000000000000000000000000000000000000;

// Optional

// Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different resolvers for the same network)
uint96 SUBNETWORK_ID = 0;
// Metadata URI of the Network
string METADATA_URI = "";
// Salt for deterministic deployment
bytes11 SALT = "SymNetwork";
```

Edit needed fields, and execute the script via:

```bash
forge script script/DeployGovTokenStaking.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --verify
```

In the console, you will see logs like these:

```bash
Deploying vault...
Deployed vault
  vault:0xDc4BD9548f09e93BCe776AB8E4C9500854C5B9c6
  delegator:0x82B2B8A683e2003d89858887d44104eD6D0a9aB7
  slasher:0x70EBb233696699863e2f060a02f6A78fadd1A0bB
Deploying network...
Deployed network
  network:0xC1989b8395671DbAbDaB8F574532876eD6e50924
  proxyAdminContract:0xb15cB056671c5079845980E75eDD65630dE62598
  newImplementation:0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
  salt:0x53796d4e6574776f726b00000000000000000000000000000000000000000000
Opted network into vault
  network:0xC1989b8395671DbAbDaB8F574532876eD6e50924
  vault:0xDc4BD9548f09e93BCe776AB8E4C9500854C5B9c6
  subnetworkId:0
  maxNetworkLimit:115792089237316195423570985008687907853269984665640564039457584007913129639935
Opting-in vault to network...
Deployment completed successfully!
  Vault address: 0xDc4BD9548f09e93BCe776AB8E4C9500854C5B9c6
  Network address: 0xC1989b8395671DbAbDaB8F574532876eD6e50924
```

### Examples

#### Lombard CCIP

##### Deploy

1. Deploy LINK Vault
2. Deploy Lombard CCIP Network and opt-in it to the LINK Vault
3. Opt-in LINK Vault to the Network
4. Transfer Vault roles
5. Opt-in Network to BARD Vault
6. Transfer Network Roles

```bash
forge script script/examples/ccip/Deploy.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --verify
```

##### Set deposit limit

```bash
forge script script/examples/ccip/SetDepositLimit.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```

##### Transfer Vault Roles

```bash
forge script script/examples/ccip/TransferVaultRoles.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```

##### Opt into vault

```bash
forge script script/examples/ccip/OptIntoVault.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```

##### Transfer Network Roles

```bash
forge script script/examples/ccip/TransferNetworkRoles.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```

#### Solv CCIP

##### Deploy

1. Deploy Solv CCIP Network and opt-in it to the LINK Vault
2. Opt-in Network to SOLV Vault
3. Transfer Network Roles

```bash
forge script script/examples/solvCCIP/Deploy.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --verify
```

##### Opt into vault

```bash
forge script script/examples/solvCCIP/OptIntoVault.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```

##### Transfer Network Roles

```bash
forge script script/examples/solvCCIP/TransferNetworkRoles.s.sol --rpc-url https://mainnet.gateway.tenderly.co --ledger --broadcast
```
