// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {DeployForCCIP} from "./DeployForCCIP.s.sol";
import {TransferRolesCCIP} from "./TransferRolesCCIP.s.sol";

contract Test is Script {
    function run() public {
        (new DeployForCCIP()).run();
        (new TransferRolesCCIP()).run();
    }
}
