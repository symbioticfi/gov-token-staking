// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";

contract SetDepositLimit is Script {
    address VAULT = 0xD538A11e421449F2BAFA153F678C81E7a4f411B3; // TODO
    uint256 DEPOSIT_LIMIT = 4_060_000 * 1e18; // TODO

    function run() public {
        vm.startBroadcast();
        IVault(VAULT).setDepositLimit(DEPOSIT_LIMIT);
        assert(IVault(VAULT).depositLimit() == DEPOSIT_LIMIT);
        vm.stopBroadcast();
        console2.log("Deposit limit set successfully!");
    }
}
