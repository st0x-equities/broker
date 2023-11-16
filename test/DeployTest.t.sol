// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "./Utils.sol";

contract DeployTest is Test, Utils {
    IFlowERC20V4 flow20;
    Evaluable evalueable;
    function test_deploy() public {
        setMumbaiFork();
        FlowDeployed memory flowDeployed = deploy();
        flow20 = flowDeployed.flow;
        evalueable = flowDeployed.expressions[0];

        console2.log("flow20 address: ", address(flow20));
    }
}
