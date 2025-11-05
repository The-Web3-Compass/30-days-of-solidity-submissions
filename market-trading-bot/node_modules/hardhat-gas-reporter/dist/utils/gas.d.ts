import { TransactionSerializableGeneric } from 'viem';
import { GasReporterOptions, JsonRpcTx } from "../types";
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
export declare function getOptimismBedrockL1Gas(tx: JsonRpcTx): number;
/**
 * Gets the native token denominated cost of registering tx calldata to L1
 * @param txDataGas            amount obtained from `getOptimismBedrockL1Gas`
 * @param baseFee              amount obtained from previous block
 * @returns
 */
export declare function getOptimismBedrockL1Cost(txDataGas: number, baseFee: number): number;
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
export declare function getOPStackEcotoneL1Cost(txSerialized: number, baseFee: number, blobBaseFee: number, opStackBaseFeeScalar: number, opStackBlobBaseFeeScalar: number): number;
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
export declare function getOPStackDataGas(tx: JsonRpcTx): number;
export declare function getArbitrumL1Bytes(tx: JsonRpcTx): number;
export declare function getArbitrumL1Cost(bytes: number, gasPrice: number, baseFeePerByte: number): number;
/**
 * Serializes transaction
 * @param tx
 * @returns
 */
export declare function getSerializedTx(_tx: JsonRpcTx, emulateSignatureComponents?: boolean): string;
export declare function toTransactionSerializable(_tx: JsonRpcTx): TransactionSerializableGeneric;
/**
 * Computes the intrinsic gas overhead for the data component of a transaction
 * @param data
 * @returns
 */
export declare function getCalldataBytesGas(data: string): number;
/**
 * Returns estimate of the intrinsic gas used for executing a tx on L1 EVM;
 * @param tx
 * @returns
 */
export declare function getIntrinsicGas(data: string): number;
/**
 * Returns gas cost minus the intrinsic gas call overhead for a transaction
 * @param data
 * @param gas
 * @returns
 */
export declare function getGasSubIntrinsic(data: string, gas: number): number;
/**
 * Gets calldata gas amount for network by hardfork
 * @param options      GasReporterOptions
 * @param tx           JSONRPC formatted transaction
 * @returns
 */
export declare function getCalldataGasForNetwork(options: GasReporterOptions, tx: JsonRpcTx): number;
/**
 * Gets calldata gas X gas price for network by hardfork
 * @param options        GasReporterOptions
 * @param gas            Scaled gas value collected
 * @param baseFee        Network fee from block
 * @param blobBaseFee    Network fee from block
 * @returns
 */
export declare function getCalldataCostForNetwork(options: GasReporterOptions, gas: number): number;
/**
 * Expresses gas usage as a nation-state currency price
 * @param  {Number} executionGas      execution gas used
 * @param  {Number} calldataGas       data gas used
 * @param  {GasReporterOptions}       options
 * @return {string}                   cost of gas used "0.00"
 */
export declare function gasToCost(executionGas: number, calldataGas: number, options: GasReporterOptions): string;
/**
 * Expresses gas usage as a % of the block gasLimit. Source: NeuFund (see issues)
 * @param  {Number} gasUsed    gas value
 * @param  {Number} blockLimit gas limit of a block
 * @return {Number}            percent (0.0)
 */
export declare function gasToPercentOfLimit(gasUsed: number, blockLimit: number): number;
/**
 * Converts hex to decimal
 * @param  {string}     hex JSONRPC val
 * @return {Number}     decimal
 */
export declare function hexToDecimal(val: string): number;
/**
 * Converts hex to bigint
 * @param  {string}     hex JSONRPC val
 * @return {BigInt}     bigint
 */
export declare function hexToBigInt(val: string): bigint;
export declare function hexWeiToIntGwei(val: string): number;
/**
 * Converts wei `l1 fee estimate` to gwei estimated price per byte
 * @param val
 */
export declare function getArbitrumBaseFeePerByte(val: number): number;
//# sourceMappingURL=gas.d.ts.map