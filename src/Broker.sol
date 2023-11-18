// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "rain.factory/src/interface/ICloneableFactoryV2.sol";
import "rain.interpreter/src/interface/IInterpreterV1.sol";
import "rain.interpreter/src/interface/IInterpreterStoreV1.sol";
import "../test/contracts/ReserveToken.sol";

ICloneableFactoryV2 constant factory = ICloneableFactoryV2(0xAB69D80Cc48763a6EaF38Fd68bE3933782D45507);
address constant implementation = 0x48FD7faEA344aBDCa8Bea0a85faF8C8740eeCB10;

IInterpreterV1 constant interpreter = IInterpreterV1(0x42a6A4A7F1D6715c8Bd98Ab0C95404898FA633D8);
IInterpreterStoreV1 constant store = IInterpreterStoreV1(0x463199A664ff46978D4Ef9cC6fCc28A796E51D5D);
address constant deployer = 0x3810Fc80caaD01001b999424e24cCd4117939fEf;

ReserveToken constant usdc = ReserveToken(0xC06A96B36c89D2b37d8635e6Ef5fF518A2BC5cE9);

address constant couponSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

uint256 constant couponSignerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

address constant orderbook = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;

address constant ST0x = 0x ; //Vish to input, this will be ST0x's wallet for fee collection 

bytes constant PRELUDE = "sentinel: 115183058774379759847873638693462432260838474092724525396123647190314935293775," // sentinel value
    "caller: context<0 0>()," // caller address
    "signer: context<2 0>()," // signer address
    "ob: 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD," // orderbook address
    "expected-signer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266," // expected signer address
    "usdt: 0xC06A96B36c89D2b37d8635e6Ef5fF518A2BC5cE9,"; // usdt address"

bytes constant SIGNED_CONTEXT = "coupon-domain-seperator: context<3 0>()," // domain seperator
    "broker: context<3 1>()," // broker id
    "amount-limit: context<3 2>()," // buy limit
    "io-ratio: context<3 3>()," // input/output ratio
    "coupon-expiry: context<3 4>(),"; // coupon expiry timestamp

bytes constant CALLER_CONTEXT = "input-token: context<1 0>()," // taking input token from signedContext
    "input-amount: context<1 1>()," // taking buy amount from callerContext
    "output-token: context<1 2>()," // taking output token from signedContext
    "volume-record-key: hash(coupon-domain-seperator coupon-expiry),"; // key for volume record

bytes constant CONDITIONS = 
    ":ensure<0>(equal-to(signer expected-signer))," // check if context is signed by signer-address
    ":ensure<1>(equal-to(coupon-domain-seperator hash(input-token output-token ob)))," // check if coupon-domain-seperator is valid
    ":ensure<2>(less-than(block-timestamp() coupon-expiry)),"; // check if coupon is not expired
    // ":ensure<3>(less-than(input-amount amount-limit)),"; // check if input amount is less than buy limit

bytes constant TRANSFERS = 
    "asked-amount: decimal18-div(input-amount io-ratio),"
    "condition: less-than(decimal18-add(asked-amount get(volume-record-key)) amount-limit),"
    "trade-amount: if(condition input-amount decimal18-div(decimal18-sub(amount-limit get(volume-record-key)) io-ratio)),"
    // if input amount is less than buy limit, then trade input amount, else trade buy limit - volume record
    "fee: decmial18-mul(trade-amount 2000000000000000)," // calculates the brokers fee
    "trade-amount-post-fee: decmial18-mul(trade-amount 998000000000000000),"// calculates the trade amount without the fee
    "output-size: decimal18-div(trade-amount-post-fee io-ratio)," // calculate output amount
    "transfererc1155slist: sentinel," "transfererc721slist: sentinel," "transfererc20slist: sentinel,"
    "_ _ _ _: usdt caller broker trade-amount-post-fee," // transfer trade amount of usdt from caller to broker
    "_ _ _ _: usdt caller ST0x fee," // transfer usdt from caller to ST0x
    "burnslist: sentinel," "mintslist: sentinel," // burn and mint sentinels
    "_ _: caller output-size,"; // mint flow20 to caller

bytes constant POST_TRANSFERS = ":set(volume-record-key decimal18-add(get(volume-record-key) output-size));"; // update volume record in output 

function getFlowScript() pure returns (bytes memory) {
    return bytes.concat(PRELUDE, SIGNED_CONTEXT, CALLER_CONTEXT, CONDITIONS, TRANSFERS, POST_TRANSFERS);
}

bytes constant CAN_TRANSFER_SCRIPT = "_ : 1;"; // allow all transfers
