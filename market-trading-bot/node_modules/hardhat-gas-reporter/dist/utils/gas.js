"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getArbitrumBaseFeePerByte = exports.hexWeiToIntGwei = exports.hexToBigInt = exports.hexToDecimal = exports.gasToPercentOfLimit = exports.gasToCost = exports.getCalldataCostForNetwork = exports.getCalldataGasForNetwork = exports.getGasSubIntrinsic = exports.getIntrinsicGas = exports.getCalldataBytesGas = exports.toTransactionSerializable = exports.getSerializedTx = exports.getArbitrumL1Cost = exports.getArbitrumL1Bytes = exports.getOPStackDataGas = exports.getOPStackEcotoneL1Cost = exports.getOptimismBedrockL1Cost = exports.getOptimismBedrockL1Gas = void 0;
const viem_1 = require("viem");
const brotli_wasm_1 = require("brotli-wasm");
const constants_1 = require("../constants");
/**
==========================
OPTIMISM BEDROCK
==========================
Given:

+ A fixed overhead cost for publishing a transaction (currently set to 188 gas).
+ A dynamic overhead cost which scales with the size of the transaction (currently set to 0.684).

Count the number of zero bytes and non-zero bytes in the transaction data. Each zero byte
costs 4 gas and each non-zero byte costs 16 gas.
```
tx_data_gas = count_zero_bytes(tx_data) * 4 + count_non_zero_bytes(tx_data) * 16
tx_total_gas = (tx_data_gas + fixed_overhead) * dynamic_overhead
l1_data_fee = tx_total_gas * ethereum_base_fee
```
Source: https://docs.optimism.io/stack/transactions/fees#formula
*/
/**
 * Gets calldata gas plus overhead for a tx (an input into the function below)
 * @param tx        JSONRPC formatted getTransaction response
 * @returns
 */
function getOptimismBedrockL1Gas(tx) {
    const txDataGas = getOPStackDataGas(tx);
    return txDataGas + constants_1.OPTIMISM_BEDROCK_FIXED_OVERHEAD;
}
exports.getOptimismBedrockL1Gas = getOptimismBedrockL1Gas;
/**
 * Gets the native token denominated cost of registering tx calldata to L1
 * @param txDataGas            amount obtained from `getOptimismBedrockL1Gas`
 * @param baseFee              amount obtained from previous block
 * @returns
 */
function getOptimismBedrockL1Cost(txDataGas, baseFee) {
    return Math.floor(constants_1.OPTIMISM_BEDROCK_DYNAMIC_OVERHEAD * txDataGas) * baseFee;
}
exports.getOptimismBedrockL1Cost = getOptimismBedrockL1Cost;
/*
 * ==========================
 * OPTIMISM ECOTONE
 * ==========================
 *
 * The Ecotone L1 Data Fee calculation begins with counting the number of zero bytes and non-zero bytes
 * in the transaction data. Each zero byte costs 4 gas and each non-zero byte costs 16 gas. This value,
 * when divided by 16, can be thought of as a rough estimate of the size of the transaction data after
 * compression.
 *
 * ```
 * tx_compressed_size = [(count_zero_bytes(tx_data)*4 + count_non_zero_bytes(tx_data)*16)] / 16
 * ``
 * Next, the two scalars are applied to the base fee and blob base fee parameters to compute a weighted
 * gas price multiplier.
 *
 * ```
 * weighted_gas_price = 16*base_fee_scalar*base_fee + blob_base_fee_scalar*blob_base_fee
 * ```
 *
 * The l1 data fee is then:
 *
 * ```
 * l1_data_fee = tx_compressed_size * weighted_gas_price
 * ```
 *
 *
 * Source: https://github.com/ethereum-optimism/optimism/blob/e57787ea7d0b9782cea5f32bcb92d0fdeb7bd870/ +
 *         packages/contracts-bedrock/src/L2/GasPriceOracle.sol#L88-L92
 *
 * DECIMALS = 6
 *
 * function _getL1FeeEcotone(bytes memory _data) internal view returns (uint256) {
 *       uint256 l1GasUsed = _getCalldataGas(_data);
 *       uint256 scaledBaseFee = baseFeeScalar() * 16 * l1BaseFee();
 *       uint256 scaledBlobBaseFee = blobBaseFeeScalar() * blobBaseFee();
 *       uint256 fee = l1GasUsed * (scaledBaseFee + scaledBlobBaseFee);
 *       return fee / (16 * 10 ** DECIMALS);
 *   }
 */
/**
 * Gets the native token denominated cost of registering tx calldata to L1
 * @param txSerialized
 * @param txCompressed
 * @param baseFee
 * @param blobBaseFee
 * @param opStackBaseFeeScalar
 * @param opStackBlobBaseFeeScalar
 * @returns
 */
function getOPStackEcotoneL1Cost(txSerialized, baseFee, blobBaseFee, opStackBaseFeeScalar, opStackBlobBaseFeeScalar) {
    const weightedBaseFee = 16 * opStackBaseFeeScalar * baseFee;
    const weightedBlobBaseFee = opStackBlobBaseFeeScalar * blobBaseFee;
    return (txSerialized * (weightedBaseFee + weightedBlobBaseFee)) / 16000000;
}
exports.getOPStackEcotoneL1Cost = getOPStackEcotoneL1Cost;
/**
 * Computes the amount of L1 gas used for a transaction. The overhead represents the per batch
 * gas overhead of posting both transaction and state roots to L1 given larger batch sizes.
 *
 *  4   gas for 0 byte
 * 16   gas for non zero byte
 *
 * Account for the transaction being unsigned. Padding is added to account for lack of signature
 * on transaction.  (Assume VRS components are non-zero)
 *
 *         1   byte for RLP V prefix
 *         1   byte for V
 *         1   byte for RLP R prefix
 *        32   bytes for R
 *         1   byte for RLP S prefix
 *        32   bytes for S
 * ----------
 * Total: 68   bytes of padding
 *
 * SOURCE: optimism/packages/contracts/contracts/L2/predeploys/OVM_GasPriceOracle.sol
 */
function getOPStackDataGas(tx) {
    const serializedTx = getSerializedTx(tx);
    const total = getCalldataBytesGas(serializedTx);
    return total + (68 * 16);
}
exports.getOPStackDataGas = getOPStackDataGas;
// ==========================
// ARBITRUM OS20
// ==========================
function getArbitrumL1Bytes(tx) {
    const serializedTx = getSerializedTx(tx);
    const compressedTx = (0, brotli_wasm_1.compress)(Buffer.from(serializedTx), { quality: 2 });
    const compressedLength = Buffer.from(compressedTx).toString('utf8').length;
    return compressedLength + 140;
}
exports.getArbitrumL1Bytes = getArbitrumL1Bytes;
function getArbitrumL1Cost(bytes, gasPrice, baseFeePerByte) {
    // Debit 10% estimate buffer
    const adjustedBaseFeePerByte = Math.round(baseFeePerByte - (baseFeePerByte / 10));
    const l1Gas = adjustedBaseFeePerByte * 1e9 * bytes;
    const l1Cost = l1Gas / (gasPrice * 1e9);
    return l1Cost;
}
exports.getArbitrumL1Cost = getArbitrumL1Cost;
/**
 * Serializes transaction
 * @param tx
 * @returns
 */
function getSerializedTx(_tx, emulateSignatureComponents = false) {
    let signature;
    const tx = toTransactionSerializable(_tx);
    const type = (0, viem_1.getTransactionType)(tx);
    // For arbitrum - part of their estimation flow at nitro
    // TEMORARILY DISABLED DUE TO CRASH REPORTED IN ISSUE #258
    if (emulateSignatureComponents) {
        signature = {
            v: BigInt(0),
            r: constants_1.RANDOM_R_COMPONENT,
            s: constants_1.RANDOM_S_COMPONENT
        };
    }
    return (0, viem_1.serializeTransaction)({
        to: tx.to,
        maxFeePerGas: tx.maxFeePerGas,
        maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
        data: tx.data,
        value: tx.value,
        chainId: tx.chainId,
        type,
        nonce: tx.nonce,
    }, signature);
}
exports.getSerializedTx = getSerializedTx;
function toTransactionSerializable(_tx) {
    return {
        data: _tx.data ? _tx.data : _tx.input,
        to: _tx.to,
        value: hexToBigInt(_tx.value),
        nonce: parseInt(_tx.nonce),
        gas: (_tx.gas) ? hexToBigInt(_tx.gas) : BigInt(0),
        maxFeePerGas: (_tx.maxFeePerGas) ? hexToBigInt(_tx.maxFeePerGas) : BigInt(0),
        maxPriorityFeePerGas: (_tx.maxPriorityFeePerGas) ? hexToBigInt(_tx.maxPriorityFeePerGas) : BigInt(0),
        chainId: (_tx.chainId === undefined) ? 1337 : parseInt(_tx.chainId),
    };
}
exports.toTransactionSerializable = toTransactionSerializable;
/**
 * Computes the intrinsic gas overhead for the data component of a transaction
 * @param data
 * @returns
 */
function getCalldataBytesGas(data) {
    let total = 0;
    // String hex-prefixed, 1 byte = 2 hex chars
    for (let i = 2; i < data.length; i++) {
        if (i % 2 === 0) {
            total = (data[i] === "0" && data[i + 1] === "0")
                ? total + 4
                : total + 16;
        }
    }
    return total;
}
exports.getCalldataBytesGas = getCalldataBytesGas;
/**
 * Returns estimate of the intrinsic gas used for executing a tx on L1 EVM;
 * @param tx
 * @returns
 */
function getIntrinsicGas(data) {
    const gas = getCalldataBytesGas(data);
    return gas + constants_1.EVM_BASE_TX_COST;
}
exports.getIntrinsicGas = getIntrinsicGas;
/**
 * Returns gas cost minus the intrinsic gas call overhead for a transaction
 * @param data
 * @param gas
 * @returns
 */
function getGasSubIntrinsic(data, gas) {
    const intrinsic = getIntrinsicGas(data);
    return gas - intrinsic;
}
exports.getGasSubIntrinsic = getGasSubIntrinsic;
/**
 * Gets calldata gas amount for network by hardfork
 * @param options      GasReporterOptions
 * @param tx           JSONRPC formatted transaction
 * @returns
 */
function getCalldataGasForNetwork(options, tx) {
    if (options.L2 === "optimism" || options.L2 === "base") {
        switch (options.optimismHardfork) {
            case "bedrock": return getOptimismBedrockL1Gas(tx);
            case "ecotone": return getOPStackDataGas(tx);
            default: return 0; /** This shouldn't happen */
        }
    }
    if (options.L2 === "arbitrum") {
        return getArbitrumL1Bytes(tx);
    }
    // If not configured for L2
    return 0;
}
exports.getCalldataGasForNetwork = getCalldataGasForNetwork;
/**
 * Gets calldata gas X gas price for network by hardfork
 * @param options        GasReporterOptions
 * @param gas            Scaled gas value collected
 * @param baseFee        Network fee from block
 * @param blobBaseFee    Network fee from block
 * @returns
 */
function getCalldataCostForNetwork(options, gas) {
    if (options.L2 === "optimism" || options.L2 === "base") {
        switch (options.optimismHardfork) {
            case "bedrock": return getOptimismBedrockL1Cost(gas, options.baseFee);
            case "ecotone": return getOPStackEcotoneL1Cost(gas, options.baseFee, options.blobBaseFee, options.opStackBaseFeeScalar, options.opStackBlobBaseFeeScalar);
            default: return 0; /** This shouldn't happen */
        }
    }
    if (options.L2 === "arbitrum") {
        return getArbitrumL1Cost(gas, options.gasPrice, options.baseFeePerByte);
    }
    // If not configured for L2
    return 0;
}
exports.getCalldataCostForNetwork = getCalldataCostForNetwork;
/**
 * Expresses gas usage as a nation-state currency price
 * @param  {Number} executionGas      execution gas used
 * @param  {Number} calldataGas       data gas used
 * @param  {GasReporterOptions}       options
 * @return {string}                   cost of gas used "0.00"
 */
function gasToCost(executionGas, calldataGas, options) {
    let calldataCost = 0;
    if (options.L2) {
        const cost = getCalldataCostForNetwork(options, calldataGas);
        if (options.L2 === "optimism" || options.L2 === "base") {
            calldataCost = (cost / 1e9) * parseFloat(options.tokenPrice);
        }
        if (options.L2 === "arbitrum") {
            executionGas += cost;
        }
    }
    const executionCost = (options.gasPrice / 1e9) * executionGas * parseFloat(options.tokenPrice);
    return (executionCost + calldataCost).toFixed(options.currencyDisplayPrecision);
}
exports.gasToCost = gasToCost;
/**
 * Expresses gas usage as a % of the block gasLimit. Source: NeuFund (see issues)
 * @param  {Number} gasUsed    gas value
 * @param  {Number} blockLimit gas limit of a block
 * @return {Number}            percent (0.0)
 */
function gasToPercentOfLimit(gasUsed, blockLimit) {
    return Math.round((1000 * gasUsed) / blockLimit) / 10;
}
exports.gasToPercentOfLimit = gasToPercentOfLimit;
/**
 * Converts hex to decimal
 * @param  {string}     hex JSONRPC val
 * @return {Number}     decimal
 */
function hexToDecimal(val) {
    return parseInt(val.toString(), 16);
}
exports.hexToDecimal = hexToDecimal;
/**
 * Converts hex to bigint
 * @param  {string}     hex JSONRPC val
 * @return {BigInt}     bigint
 */
function hexToBigInt(val) {
    return BigInt(val);
}
exports.hexToBigInt = hexToBigInt;
function hexWeiToIntGwei(val) {
    return hexToDecimal(val) / Math.pow(10, 9);
}
exports.hexWeiToIntGwei = hexWeiToIntGwei;
/**
 * Converts wei `l1 fee estimate` to gwei estimated price per byte
 * @param val
 */
function getArbitrumBaseFeePerByte(val) {
    const gwei = (BigInt(16) * BigInt(val)) / BigInt(Math.pow(10, 9));
    return parseInt(gwei.toString());
}
exports.getArbitrumBaseFeePerByte = getArbitrumBaseFeePerByte;
//# sourceMappingURL=gas.js.map