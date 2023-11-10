// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "forge-std/Script.sol";
import "rain.flow/concrete/erc20/FlowERC20.sol";

contract Implementation is Script {
    function run(bytes memory meta) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);
        DeployerDiscoverableMetaV2ConstructionConfig memory config;
        console2.log("meta hash:");
        console2.logBytes32(keccak256(meta));
        config.deployer = 0x378A4326d8F12c6ECcC37746F1Ac2302F9c093B8;
        config.meta = meta;

        FlowERC20 flow721 = new FlowERC20(config);
        vm.stopBroadcast();
        console2.log("Deployed Flow721Implementation at address: ", address(flow721));
    }
}

// rain meta build -i <(rain meta solc artifact -c abi -i out/FlowERC721.sol/FlowERC721.json) -m solidity-abi-v2 -t json -e deflate -l en  -i src/concrete/erc721/FlowERC721.meta.json -m interpreter-caller-meta-v1 -t json -e deflate -l en -E hex
// rain meta build -i <(rain meta solc artifact -c abi -i out/FlowERC20.sol/FlowERC20.json) -m solidity-abi-v2 -t json -e deflate -l en -E hexc