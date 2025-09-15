// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {Deploy} from "./Deploy.s.sol";
import {SetDepositLimit} from "./SetDepositLimit.s.sol";
import {OptIntoVault} from "./OptIntoVault.s.sol";
import {TransferVaultRoles} from "./TransferVaultRoles.s.sol";
import {TransferNetworkRoles} from "./TransferNetworkRoles.s.sol";

contract Test is Script {
    function run() public {
        (new Deploy()).run();
        (new SetDepositLimit()).run();
        (new TransferVaultRoles()).run();
        (new OptIntoVault()).run();
        (new TransferNetworkRoles()).run();
    }
}
