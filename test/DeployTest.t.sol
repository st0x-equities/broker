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
        assertNotEq(address(flow20), address(0));
    }
}
 