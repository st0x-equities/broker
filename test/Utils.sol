// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "../src/Broker.sol";
import "rain.flow/interface/unstable/IFlowERC20V4.sol";
import "rain.interpreter/src/interface/unstable/IParserV1.sol";
import "rain.interpreter/src/interface/unstable/IExpressionDeployerV2.sol";
import {ECDSAUpgradeable as ECDSA} from "openzeppelin/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from  "openzeppelin/interfaces/IERC20Upgradeable.sol";

struct FlowDeployed {
    IFlowERC20V4 flow;
    Evaluable[] expressions;
}

contract Utils is Test {
    function setMumbaiFork() public {
        string memory mumbaiRPCURL = "https://rpc.ankr.com/polygon_mumbai";
        uint256 fork = vm.createFork(mumbaiRPCURL);
        vm.selectFork(fork);
        vm.rollFork(42249360);
        vm.label(address(usdc), "usdc");
        vm.label(couponSigner, "couponSigner");
        vm.label(orderbook, "orderbook");
    }

    function deploy() public returns (FlowDeployed memory) {
        (bytes memory bytecode, uint256[] memory constants) = IParserV1(deployer).parse(getFlowScript());
        (bytes memory canTransferBytecode, uint256[] memory canTransferConstants) =
            IParserV1(deployer).parse(CAN_TRANSFER_SCRIPT);
        FlowERC20ConfigV2 memory config;
        config.name = "SOX BROKER";
        config.symbol = "SOX";
        config.evaluableConfig =
            EvaluableConfigV2(IExpressionDeployerV2(deployer), canTransferBytecode, canTransferConstants);
        config.flowConfig = new EvaluableConfigV2[](1);
        config.flowConfig[0] = EvaluableConfigV2(IExpressionDeployerV2(deployer), bytecode, constants);

        vm.recordLogs();
        address flow20 = factory.clone(implementation, abi.encode(config));
        vm.label(flow20, "flow20");

        Vm.Log[] memory logs = vm.getRecordedLogs();
        (, Evaluable memory evalueable) = abi.decode(getFlowInitializedEvent(logs, 0).data, (address, Evaluable));

        Evaluable[] memory expressions = new Evaluable[](3);
        expressions[0] = evalueable;

        return FlowDeployed(IFlowERC20V4(flow20), expressions);
    }

    function signContext(uint256 privateKey, uint256[] memory context) public pure returns (SignedContextV1 memory) {
        SignedContextV1 memory signedContext;

        // Store the signer's address in the struct
        signedContext.signer = vm.addr(privateKey);
        signedContext.context = context; // copy the context data into the struct

        // Create a digest of the context data
        bytes32 contextHash = keccak256(abi.encodePacked(context));
        bytes32 digest = ECDSA.toEthSignedMessageHash(contextHash);

        // Create the signature using the cheatcode 'sign'
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        signedContext.signature = abi.encodePacked(r, s, v);

        return signedContext;
    }

    function getFlowInitializedEvent(Vm.Log[] memory logs, uint256 index) public pure returns (Vm.Log memory) {
        uint256 count;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("FlowInitialized(address,(address,address,address))")) {
                if (count == index) {
                    return logs[i];
                }
                count++;
            }
        }
        revert("FlowInitialized event not found");
    }
}
