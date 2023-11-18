// SPDX-License-Identyfier: Unlicensed

pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "./Utils.sol";

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

    function test_buyUnderCouponLimit() public {
        uint256 couponExpiry = block.timestamp + 100; // coupon will expire

        address alice = makeAddr("alice"); // caller who is buying btc

        address broker = makeAddr("broker"); // broker who is selling btc and will receive usdc
        address btc = makeAddr("btc"); // dummy btc address

        uint256 btcPrice = 30000; // 30000 USDC per BTC

        uint256 amountLimit = 5e18; // 5 BTC broker can sell only this much btc, 1 BTC = 1e18
        uint256 buyAmount = 1000; // 1000 USDC, buy BTC worth 1000 USDC

        uint256 tradeAmount = buyAmount; // expected trade amount
        uint256 outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
        uint256 expectedtradeAmount = buyAmount * 1e6;

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
        usdc.mint(expectedtradeAmount);
        usdc.approve(address(flow), expectedtradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();

        /**
         * broker receives 1000 USDC i.e. 1000 * 1e6 = 1000000000000
         */
        assertEq(usdc.balanceOf(broker), expectedtradeAmount);
        /**
         * alice reveives 33333333333333333 flow20 tokens which is 0.033333333333333333 BTC
         * 1000 / 30000 = 0.033333333333333333 BTC
         */
        assertEq(IERC20(address(flow)).balanceOf(alice), outputSize);
    }

    function test_buyBTCAtMaxLimit() public {
        uint256 couponExpiry = block.timestamp + 100; // coupon will expire

        address alice = makeAddr("alice"); // caller who is buying btc

        address broker = makeAddr("broker"); // broker who is selling btc and will receive usdc
        address btc = makeAddr("btc"); // dummy btc address

        uint256 btcPrice = 30000; // 30000 USDC per BTC

        uint256 amountLimit = 5e18; // 5 BTC broker can sell only this much btc, 1 BTC = 1e18
        uint256 buyAmount = 5 * btcPrice; // 150000 USDC, buy BTC worth 150000 USDC i.e 5BTC

        uint256 tradeAmount = buyAmount; // expected trade amount
        uint256 outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
        uint256 expectedtradeAmount = buyAmount * 1e6;

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
        usdc.mint(expectedtradeAmount);
        usdc.approve(address(flow), expectedtradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();

        assertEq(usdc.balanceOf(broker), expectedtradeAmount);
        assertEq(IERC20(address(flow)).balanceOf(alice), outputSize);
    }

    function test_buyMaxBTCCollectively() public {
        uint256 couponExpiry = block.timestamp + 100; // coupon will expire

        address broker = makeAddr("broker"); // broker who is selling btc and will receive usdc
        address btc = makeAddr("btc"); // dummy btc address

        uint256 btcPrice = 30000; // 30000 USDC per BTC

        uint256 amountLimit = 6e18; // 5 BTC broker can sell only this much btc, 1 BTC = 1e18
        uint256 buyAmount = 1 * btcPrice; // 30000 USDC, buy BTC worth 30000 USDC i.e 1BTC

        uint256 tradeAmount = buyAmount; // expected trade amount
        uint256 outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
        uint256 expectedtradeAmount = buyAmount * 1e6;

        uint256[] memory context = new uint256[](5);
        context[0] = uint256(keccak256(abi.encode(address(usdc), btc, orderbook)));
        context[1] = uint256(uint160(broker));
        context[2] = amountLimit; // amount-limit
        context[3] = btcPrice; // io-ratio
        context[4] = couponExpiry;

        SignedContextV1[] memory signedContext = new SignedContextV1[](1);

        uint256[] memory callerContext = new uint256[](3);
        callerContext[0] = uint256(uint160(address(usdc)));
        callerContext[2] = uint256(uint160(btc));

        for (uint256 i = 1; i <= 3; i++) {
            buyAmount = i * btcPrice; // 60000 USDC, buy BTC worth 60000 USDC i.e 2BTC

            callerContext[1] = buyAmount; // imput-amount
            signedContext[0] = signContext(couponSignerKey, context);

            tradeAmount = buyAmount; // expected trade amount
            outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
            expectedtradeAmount = buyAmount * 1e6;

            address buyer = makeAddr(vm.toString(i));
            vm.startPrank(buyer);
            usdc.mint(expectedtradeAmount);
            usdc.approve(address(flow), expectedtradeAmount);
            flow.flow(evaluable, callerContext, signedContext);
            vm.stopPrank();

            assertEq(IERC20(address(flow)).balanceOf(buyer), outputSize);
        }

        assertEq(usdc.balanceOf(broker), btcPrice * 6 * 1e6);
    }

    function test_revertToBuyAfterMaxLimit() public {
        uint256 couponExpiry = block.timestamp + 100; // coupon will expire

        address alice = makeAddr("alice"); // caller who is buying btc

        address broker = makeAddr("broker"); // broker who is selling btc and will receive usdc
        address btc = makeAddr("btc"); // dummy btc address

        uint256 btcPrice = 30000; // 30000 USDC per BTC

        uint256 amountLimit = 5e18; // 5 BTC broker can sell only this much btc, 1 BTC = 1e18
        uint256 buyAmount = 5 * btcPrice; // 150000 USDC, buy BTC worth 150000 USDC i.e 5BTC

        uint256 tradeAmount = buyAmount; // expected trade amount
        uint256 outputSize = tradeAmount.fixedPointDiv(btcPrice, Math.Rounding.Down); // expected output size in btc
        uint256 expectedtradeAmount = buyAmount * 1e6;

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
        usdc.mint(expectedtradeAmount);
        usdc.approve(address(flow), expectedtradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();

        assertEq(usdc.balanceOf(broker), expectedtradeAmount);
        assertEq(IERC20(address(flow)).balanceOf(alice), outputSize);

        address secondBuyer = makeAddr("secondBuyer");
        vm.startPrank(secondBuyer);
        usdc.mint(expectedtradeAmount);
        usdc.approve(address(flow), expectedtradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();

        assertEq(usdc.balanceOf(broker), expectedtradeAmount);
        assertEq(IERC20(address(flow)).balanceOf(secondBuyer), 0);
    }
}
