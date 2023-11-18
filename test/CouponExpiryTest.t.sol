// SPDX-License_Identyfier: Unlicensed

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "./Utils.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";

contract CouponExpiryTest is Test, Utils {
    IFlowERC20V4 flow;
    Evaluable evaluable;

    function setUp() public {
        setMumbaiFork();
        FlowDeployed memory flowDeployed = deploy();
        flow = flowDeployed.flow;
        evaluable = flowDeployed.expressions[0];
    }

    function test_revertBuyAfterCouponExpiry() public {
        uint256 couponExpiry = block.timestamp + 100;
        vm.warp(couponExpiry + 10);

        address alice = makeAddr("alice");

        address broker = makeAddr("broker");
        uint256 price = 1 ether;
        address btc = makeAddr("btc");

        uint256 fakeBid = price + 1e15;
        // uint256 fakeAsk = price - 1e15;

        uint256 buyAmount = 10;
        uint256 amountLimit = price * 10;

        uint256[] memory context = new uint256[](5);
        context[0] = uint256(keccak256(abi.encode(address(usdc), btc, orderbook)));
        context[1] = uint256(uint160(broker));
        context[2] = amountLimit;
        context[3] = fakeBid;
        context[4] = couponExpiry;

        SignedContextV1[] memory signedContext = new SignedContextV1[](1);
        signedContext[0] = signContext(couponSignerKey, context);

        uint256[] memory callerContext = new uint256[](3);
        callerContext[0] = uint256(uint160(address(usdc)));
        callerContext[1] = buyAmount;
        callerContext[2] = uint256(uint160(btc));

        vm.startPrank(alice);
        usdc.mint(amountLimit);
        usdc.approve(address(flow), amountLimit);
        vm.expectRevert();
        flow.flow(evaluable, callerContext, signedContext);

        vm.stopPrank();
    }

    function testFuzz_mintBeforeCouponExpiry(uint256 timestamp) public {
        uint256 couponExpiry = block.timestamp + 100;
        vm.assume(timestamp < couponExpiry);
        vm.warp(timestamp);
        address alice = makeAddr("alice");

        address broker = makeAddr("broker");
        uint256 price = 1 ether;
        address btc = makeAddr("btc");

        uint256 fakeBid = price + (price / 1000);
        // uint256 fakeAsk = price - (price / 100000);

        uint256 buyAmount = 10;
        uint256 amountLimit = price * 10;

        uint256[] memory context = new uint256[](5);
        context[0] = uint256(keccak256(abi.encode(address(usdc), btc, orderbook)));
        context[1] = uint256(uint160(broker));
        context[2] = amountLimit;
        context[3] = fakeBid;
        context[4] = couponExpiry;

        SignedContextV1[] memory signedContext = new SignedContextV1[](1);
        signedContext[0] = signContext(couponSignerKey, context);

        uint256[] memory callerContext = new uint256[](3);
        callerContext[0] = uint256(uint160(address(usdc)));
        callerContext[1] = buyAmount;
        callerContext[2] = uint256(uint160(btc));

        vm.startPrank(alice);
        usdc.mint(amountLimit);
        usdc.approve(address(flow), amountLimit);
        flow.flow(evaluable, callerContext, signedContext);

        vm.stopPrank();
    }
}
