// SPDX-License-Identyfier: Unlicensed

pragma solidity =0.8.19;
import "forge-std/Test.sol";
import "./Utils.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
contract CouponMintTest is Test, Utils {
    
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
        uint256 couponExpiry  = block.timestamp + 100;

        address alice = makeAddr("alice");
        

        address broker = makeAddr("broker");
        uint256 price = 1 ether;
        address btc = makeAddr("btc");

        uint256 fakeBid = price + (price / 1000);
        // uint256 fakeAsk = price - (price / 100000);

        uint256 amountLimit = 10000000000000000000;
        uint256 buyAmount = amountLimit * 2;


        uint256 askprice = buyAmount / fakeBid;
        uint256 tradeAmount = amountLimit * fakeBid;
        uint256 outputSize = tradeAmount / fakeBid;
        
        console2.log("askprice", askprice);
        console2.log("amountLimit", amountLimit);
        console2.log("buyAmount", buyAmount);
        console2.log("tradeAmount", tradeAmount);
        console2.log("outputSize", outputSize);

        uint256[] memory context = new uint256[](5);
        context[0] = uint256(keccak256(abi.encode(address(usdc), btc, orderbook)));
        context[1] = uint256(uint160(broker));
        context[2] = 10000000000000000000; // buy max limit
        context[3] = fakeBid;
        context[4] = couponExpiry;

        SignedContextV1[] memory signedContext = new SignedContextV1[](1);
        signedContext[0] = signContext(couponSignerKey, context);

        uint256[] memory callerContext = new uint256[](3);
        callerContext[0] = uint256(uint160(address(usdc)));
        callerContext[1] = buyAmount;
        callerContext[2] = uint256(uint160(btc));

        vm.startPrank(alice);
        usdc.mint(tradeAmount);
        usdc.approve(address(flow), tradeAmount);
        flow.flow(evaluable, callerContext, signedContext);
        vm.stopPrank();
        assertEq(usdc.balanceOf(broker), tradeAmount);
        assertEq(IERC20(address(flow)).balanceOf(alice), outputSize);
    }
}