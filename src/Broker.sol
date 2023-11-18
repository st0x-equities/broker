// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "rain.factory/src/interface/ICloneableFactoryV2.sol";
import "rain.interpreter/src/interface/IInterpreterV1.sol";
import "rain.interpreter/src/interface/IInterpreterStoreV1.sol";
import "../test/contracts/ReserveToken.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

ICloneableFactoryV2 constant factory = ICloneableFactoryV2(0xAB69D80Cc48763a6EaF38Fd68bE3933782D45507);
address constant implementation = 0x48FD7faEA344aBDCa8Bea0a85faF8C8740eeCB10;

IInterpreterV1 constant interpreter = IInterpreterV1(0x42a6A4A7F1D6715c8Bd98Ab0C95404898FA633D8);
IInterpreterStoreV1 constant store = IInterpreterStoreV1(0x463199A664ff46978D4Ef9cC6fCc28A796E51D5D);
address constant deployer = 0x3810Fc80caaD01001b999424e24cCd4117939fEf;

ReserveToken constant usdc = ReserveToken(0xC06A96B36c89D2b37d8635e6Ef5fF518A2BC5cE9);

address constant couponSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

uint256 constant couponSignerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

address constant orderbook = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;

address constant st0x = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

bytes constant PRELUDE = "sentinel: 115183058774379759847873638693462432260838474092724525396123647190314935293775," // sentinel value
    "caller: context<0 0>()," // caller address
    "signer: context<2 0>()," // signer address
    "ob: 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD," // orderbook address
    "expected-signer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266," // expected signer address
    "usdc: 0xC06A96B36c89D2b37d8635e6Ef5fF518A2BC5cE9," // usdc address"
    "stx: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,"; // st0x address"

bytes constant SIGNED_CONTEXT = "coupon-domain-seperator: context<3 0>()," // domain seperator
    "broker: context<3 1>()," // broker id
    "amount-limit: context<3 2>()," // buy limit
    "io-ratio: context<3 3>()," // input/output ratio
    "coupon-expiry: context<3 4>(),"; // coupon expiry timestamp

bytes constant CALLER_CONTEXT = "input-token: context<1 0>()," // taking input token from signedContext
    "input-amount: context<1 1>()," // taking buy amount from callerContext
    "input-amount-scale18: decimal18-scale18<0>(input-amount)," // converting buy amount to scale18
    "output-token: context<1 2>()," // taking output token from signedContext
    "volume-record-key: hash(coupon-domain-seperator coupon-expiry),"; // key for volume record

bytes constant CONDITIONS = ":ensure<0>(equal-to(signer expected-signer))," // check if context is signed by signer-address
    ":ensure<1>(equal-to(coupon-domain-seperator hash(input-token output-token ob)))," // check if coupon-domain-seperator is valid
    ":ensure<2>(less-than(block-timestamp() coupon-expiry)),"; // check if coupon is not expired
    // ":ensure<3>(less-than(get(volume-record-key) amount-limit)),"; // check if buy limit is not reached

bytes constant TRANSFERS = "asked-amount: int-div(input-amount-scale18 io-ratio),"
    "condition: less-than-or-equal-to(int-add(asked-amount get(volume-record-key)) amount-limit),"
    "new-ratio: decimal18-sub(amount-limit get(volume-record-key)),"
    "trade-amount: if(condition input-amount decimal18-mul(io-ratio new-ratio)),"
    // if input amount is less than buy limit, then trade input amount, else trade buy limit - volume record
    "fee: decimal18-mul(trade-amount 2e15)," // calculates the brokers fee
    "trade-amount-minus-fee: decimal18-mul(trade-amount 998e15),"// calculates the trade amount without the fee
    "output-size: decimal18-div(trade-amount-minus-fee io-ratio)," // calculate output amount
    "transfererc1155slist: sentinel," "transfererc721slist: sentinel," "transfererc20slist: sentinel,"
    "_ _ _ _: usdc caller broker int-mul(trade-amount-minus-fee 1e6)," // transfer trade amount of usdc from caller to broker
    "_ _ _ _: usdc caller stx int-mul(fee 1e6)," // transfer usdc from caller to ST0x
    "burnslist: sentinel," "mintslist: sentinel," // burn and mint sentinels
    "_ _: broker trade-amount," // transfer output amount of output token to broker
    "_ _: caller output-size,"; // mint to caller

    // 5000000000000000000 - 4990000000000000000 = 10000000000000000 
    //                                             10000000000000000

bytes constant POST_TRANSFERS = ":set(volume-record-key decimal18-add(get(volume-record-key) output-size));"; // update volume record

function getFlowScript() pure returns (bytes memory) {
    return bytes.concat(PRELUDE, SIGNED_CONTEXT, CALLER_CONTEXT, CONDITIONS, TRANSFERS, POST_TRANSFERS);
}

bytes constant CAN_TRANSFER_SCRIPT = "_ : 1;"; // allow all transfers
