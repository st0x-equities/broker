// SPDX-License-Identyfier: Unlicensed

pragma solidity =0.8.19;
import "forge-std/Test.sol";
import "./Utils.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

contract CouponMintTest is Test, Utils {
    using LibFixedPointDecimalArithmeticOpenZeppelin for uint256;
    using LibFixedPointDecimalScale for uint256;
    IFlowERC20V4 flow;
    Evaluable evaluable;

    function setUp() public {
        setMumbaiFork();
        FlowDeployed memory flowDeployed = deploy();
        flow = flowDeployed.flow;
        evaluable = flowDeployed.expressions[0];
    }

    function test_revertBuyInCouponLimit() public {
        uint256 couponExpiry  = block.timestamp + 100;

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
        flow.flow(evaluable, callerContext, signedContext);

        vm.stopPrank();
    }

    function test_mintMoreThanCouponLimitiBuysExactlyCouponLimit() public {
        uint256 couponExpiry  = block.timestamp + 100; // coupon will expire

        address alice = makeAddr("alice"); // caller who is buying btc
        

        address broker = makeAddr("broker"); // broker who is selling btc and will receive usdc
        address btc = makeAddr("btc"); // dummy btc address

        uint256 btcPrice = 30000; // 30000 USDC per BTC

        uint256 amountLimit = 5e18; // 5 BTC broker can sell only this much btc, 1 BTC = 1e18
        uint256 buyAmount = 1000; // 1000 USDC, buy BTC worth 1000 USDC


        uint256 tradeAmount = buyAmount; // expected trade amount
        uint256 outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
        uint256 limitLeft = amountLimit - outputSize;

        console.log("outputSize", outputSize);
        console.log("limitLeft", limitLeft);
        console.log("Tally", outputSize + limitLeft);

        uint256[] memory context = new uint256[](5);
        context[0] = uint256(keccak256(abi.encode(address(usdc), btc, orderbook)));
        context[1] = uint256(uint160(broker));
        context[2] = amountLimit; // amount-limit
        context[3] = btcPrice; // io-ratio
        context[4] = couponExpiry;

        SignedContextV1[] memory signedContext = new SignedContextV1[](1);
        signedContext[0] = signContext(couponSignerKey, context);

        uint256[] memory callerContext = new uint256[](3);
        callerContext[0] = uint256(uint160(address(usdc)));
        callerContext[1] = buyAmount; // imput-amount
        callerContext[2] = uint256(uint160(btc));

        vm.startPrank(alice);
        usdc.mint(tradeAmount);
        usdc.approve(address(flow), tradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();
        
        assertEq(usdc.balanceOf(broker), buyAmount);
        /**
         * alice reveives 33333333333333333 flow20 tokens which is 0.033333333333333333 BTC
         * 1000 / 30000 = 0.033333333333333333 BTC
         */
        assertEq(IERC20(address(flow)).balanceOf(alice), outputSize);
    }
}