**[Symbiotic Protocol](https://symbiotic.fi) is an extremely flexible and permissionless shared security system.**

This repository contains a default Network contract and tooling to manage it. Basically, a Network contract is an [OZ's TimelockController](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol) with additional functionality to define delays for either (exact target | exact selector) or (any target | exact selector) pairs.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/symbioticfi/network)

## Documentation

- [What is Network?](https://docs.symbiotic.fi/modules/counterparties/networks)
- [What are Resolvers?](https://docs.symbiotic.fi/modules/counterparties/resolvers)
- [Network Registration](https://docs.symbiotic.fi/modules/registries#network-registration-process)

## Usage

### Dependencies

- Git ([installation](https://git-scm.com/downloads))
- foundry ([installation](https://getfoundry.sh/introduction/installation/))
- npm ([installation](https://nodejs.org/en/download/))

### Prerequisites

**Clone the repository**

```bash
git clone --recurse-submodules https://github.com/symbioticfi/network.git
```

**Install dependencies**

```bash
npm install
```

### Deploy Your Network

- If you need a pure Network deployment

  Open [DeployNetwork.s.sol](./script/DeployNetwork.s.sol), you will see config like this:

  ```solidity
  // Name of the Network
  string NAME = "My Network";
  // Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
  uint256 DEFAULT_MIN_DELAY = 3 days;
  // Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
  uint256 COLD_ACTIONS_DELAY = 14 days;
  // Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
  uint256 HOT_ACTIONS_DELAY = 0;
  // Admin address (will become executor, proposer, and default admin by default)
  address ADMIN = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

  // Optional

  // Metadata URI of the Network
  string METADATA_URI = "";
  // Salt for deterministic deployment
  bytes11 SALT = "SymNetwork";
  ```

  Edit needed fields, and execute the script via:

  ```bash
  forge script script/DeployNetwork.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --verify
  ```

- If you need a Network deployment for already-deployed Vault

  Open [DeployNetworkForVaults.s.sol](./script/DeployNetworkForVaults.s.sol), you will see config like this:

  ```solidity
  // Name of the Network
  string NAME = "My Network";
  // Default minimum delay (will be applied for any action that doesn't have a specific delay yet)
  uint256 DEFAULT_MIN_DELAY = 3 days;
  // Cold actions delay (a delay that will be applied for major actions like upgradeProxy and setMiddleware)
  uint256 COLD_ACTIONS_DELAY = 14 days;
  // Hot actions delay (a delay that will be applied for minor actions like setMaxNetworkLimit and setResolver)
  uint256 HOT_ACTIONS_DELAY = 0;
  // Admin address (will become executor, proposer, and default admin by default)
  address ADMIN = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  // Vault address to opt-in to
  address VAULT = 0x49fC19bAE549e0b5F99B5b42d7222Caf09E8d2a1;
  // Maximum amount of delegation that the network is ready to receive
  uint256 MAX_NETWORK_LIMIT = 1000;
  // Resolver address (optional, is applied only if VetoSlasher is used)
  address RESOLVER = 0xbf616b04c463b818e3336FF3767e61AB44103243;

  // Optional

  // Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different resolvers for the same network)
  uint96 SUBNETWORK_ID = 0;
  // Metadata URI of the Network
  string METADATA_URI = "";
  // Salt for deterministic deployment
  bytes11 SALT = "Test1";
  ```

  Edit needed fields, and execute the script via:

  ```bash
  forge script script/DeployNetworkForVaults.s.sol:DeployNetworkForVaults --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --verify
  ```

In the console, you will see logs like these:

```bash
Deployed network
  network:0x90F545649eDA7a2083bA30ECC5C21335d030ae1d
  proxyAdminContract:0x79d771aeC770C936E05E51fA8e68f019a373f9b1
  newImplementation:0x3C00C0ef1B1be4dFFeF07dB148bb5fbF31277091
  salt:0x5465737433000000000000000000000000000000000000000000000000000000
Opted network into vault
  network:0x90F545649eDA7a2083bA30ECC5C21335d030ae1d
  vault:0x49fC19bAE549e0b5F99B5b42d7222Caf09E8d2a1
  subnetworkId:0
  maxNetworkLimit:1000
  resolver:0xbf616b04c463b818e3336FF3767e61AB44103243
```

### Manage Your Network

There are 5 predefined [action-scripts](./script/actions/), that you can use from the start:

- [SetMaxNetworkLimit](./script/actions/SetMaxNetworkLimit.s.sol) - set new [maximum network limit](https://docs.symbiotic.fi/modules/registries#3-network-to-vault-opt-in) for the vault
- [SetResolver](./script/actions/SetResolver.s.sol) - set a new [resolver](https://docs.symbiotic.fi/modules/counterparties/resolvers) for the vault (only if the vault uses [VetoSlasher](https://docs.symbiotic.fi/modules/vault/slashing#1-vetoslasher))
- [SetMiddleware](./script/actions/SetMiddleware.s.sol) - set a new middleware
- [UpgradeProxy](./script/actions/UpgradeProxy.s.sol) - upgrade the proxy (network itself)
- [ArbitraryCall](./script/actions/ArbitraryCall.s.sol) - make a call to any contract with any data

Interaction with different actions is similar; let's consider [SetMaxNetworkLimit](./script/actions/SetMaxNetworkLimit.s.sol) as an example:

1. Open [SetMaxNetworkLimit.s.sol](./script/actions/SetMaxNetworkLimit.s.sol), you will see config like this:

   ```solidity
   // Address of the Network
   address NETWORK = 0x0000000000000000000000000000000000000000;
   // Address of the Vault
   address VAULT = 0x0000000000000000000000000000000000000000;
   // Maximum amount of delegation that network is ready to receive
   uint256 MAX_NETWORK_LIMIT = 0;
   // Delay for the action to be executed
   uint256 DELAY = 0;

   // Optional

   // Subnetwork Identifier (multiple subnetworks can be used, e.g., to have different max network limits for the same network)
   uint96 SUBNETWORK_IDENTIFIER = 0;
   // Salt for TimelockController operations
   bytes32 SALT = "SetMaxNetworkLimit";
   ```

2. Edit needed fields, and choose an operation:

   - `runS()` - schedule an action
   - `runE` - execute an action
   - `runSE()` - schedule and execute an action (possible only if a delay for the needed action is zero)

3. Execute the operation:

   - If you use an EOA and want to execute the script:

     ```bash
     forge script script/actions/SetMaxNetworkLimit.s.sol:SetMaxNetworkLimit --sig "runS()" --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
     ```

   - If you use a Safe multisig and want to get a transaction calldata:

     ```bash
     forge script script/actions/SetMaxNetworkLimit.s.sol:SetMaxNetworkLimit --sig "runS()" --rpc-url <RPC_URL> --sender <MULTISIG_ADDRESS> --unlocked
     ```

     In the logs, you will see `callData` field like this:

     ```bash
     callData:0x01d5062a00000000000000000000000025ed2ee6e295880326bdeca245ee4d8b72c8f103000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000005365744d61784e6574776f726b4c696d697400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004423f752d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002b6700000000000000000000000000000000000000000000000000000000
     ```

     In Safe->TransactionBuilder, you should:

     - enable "Custom data"
     - enter **Network's address** as a target address
     - use the `callData` (e.g., `0x01d5062a0000000000000000000000...`) received earlier as a `Data (Hex encoded)`

### Update Delays

Any action that can be made by the Network is protected by the corresponding delay (which can be any value from zero to infinity).

We provide "update delay" scripts for actions mentioned above, and also some additional ones:

- [SetMaxNetworkLimitUpdateDelay](./script/update-delay/SetMaxNetworkLimitUpdateDelay.s.sol)
- [SetResolverUpdateDelay](./script/update-delay/SetResolverUpdateDelay.s.sol)
- [SetMiddlewareUpdateDelay](./script/update-delay/SetMiddlewareUpdateDelay.s.sol)
- [UpgradeProxyUpdateDelay](./script/update-delay/UpgradeProxyUpdateDelay.s.sol)
- [HotActionsUpdateDelay](./script/update-delay/HotActionsUpdateDelay.s.sol) - update a delay for [SetMiddlewareUpdateDelay](./script/update-delay/SetMiddlewareUpdateDelay.s.sol) and [SetResolverUpdateDelay](./script/update-delay/SetResolverUpdateDelay.s.sol)
- [ColdActionsUpdateDelay](./script/update-delay/ColdActionsUpdateDelay.s.sol) - update a delay for [SetMaxNetworkLimitUpdateDelay](./script/update-delay/SetMaxNetworkLimitUpdateDelay.s.sol) and [UpgradeProxyUpdateDelay](./script/update-delay/UpgradeProxyUpdateDelay.s.sol)
- [DefaultUpdateDelay](./script/update-delay/DefaultUpdateDelay.s.sol) - update a delay for unconstrained actions
- [ArbitraryUpdateDelay](./script/update-delay/ArbitraryCallUpdateDelay.s.sol) - update a delay for an arbitrary call:
  - set a delay for the exact target address and the exact selector
  - set a delay for any target address and the exact selector (by setting target address to `0x0000000000000000000000000000000000000000`)

For example usage of similar scripts see ["Manage Your Network"](./README.md#manage-your-network).

### Dashboard

**Note: work-in-progress, use with caution**

`Network` contract inherits OpenZeppelin's `TimelockController`, while `TimelockController` inherits `AccessControl`. The similarity between `TimelockController` and `AccessControl` contracts' logic is that it is not possible to adequately determine their state (e.g., statuses of operations or holders of roles) using only the current chain's state via RPC calls. Hence, we provide a [Network Dashboard](./ui/) which allows you to:

- Get delays for all operations
- Get holders of any role
- Get scheduled/executed operations
- Schedule/execute arbitrary actions

Run the command:

```bash
npm run dev
```

## Security

Security audits can be found [here](./audits).
