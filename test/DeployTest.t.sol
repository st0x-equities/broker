// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "./Utils.sol";

contract DeployTest is Test, Utils {
    function test_deploy() public {
        setMumbaiFork();
        deploy();
    }
}
