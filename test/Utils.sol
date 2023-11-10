// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "../src/Broker.sol";
import "rain.flow/interface/unstable/IFlowERC20V4.sol";

contract Utils is Test {
    function setMumbaiFork() public {
        string memory mumbaiRPCURL = "https://rpc.ankr.com/polygon_mumbai";
        uint256 fork = vm.createFork(mumbaiRPCURL);
        vm.selectFork(fork);
        vm.rollFork(42241664);
    }

    function deploy() public pure {
        (bytes memory bytecode, uint256[] memory constants) = iDeployer.parse(getScript());

        console2.log("bytecode:");
        console2.logBytes(bytecode);
        console2.log("constants:");
        for (uint256 i = 0; i < constants.length; i++) {
            console2.logUint(constants[i]);
        }
    }
}
