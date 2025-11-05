import type { RpcReceiptOutput } from "hardhat/internal/hardhat-network/provider/output";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { GasReporterOptions, JsonRpcTx, ValidatedRequestArguments } from "../types";
import { GasData } from "./gasData";
import { Resolver } from "./resolvers";
/**
 * Collects gas usage data, associating it with the relevant contracts, methods.
 */
export declare class Collector {
    data: GasData;
    options: GasReporterOptions;
    resolver: Resolver;
    constructor(hre: HardhatRuntimeEnvironment, options: GasReporterOptions);
    /**
     * Method called by the request monitor on the provider to collect deployment
     * and methods gas data
     * @param {JsonRpcTx} transaction [description]
     * @param {TransactionReceipt} receipt     [description]
     */
    collectTransaction(tx: JsonRpcTx, receipt: RpcReceiptOutput): Promise<void>;
    /**
     * Method called by the request monitor on the provider to get gas data for `eth_call`
     * @param {ValidatedRequestArguments}    params.args  of the call
     * @param {number}                       estimate_gas result
     */
    collectCall(args: ValidatedRequestArguments, gas: number): Promise<void>;
    /**
     * Extracts and stores deployments gas usage data for a tx
     * @param  {JsonRpcTx}          tx       return value of `getTransactionByHash`
     * @param  {TransactionReceipt} receipt
     */
    private _collectDeploymentsData;
    /**
     * Extracts and stores methods gas usage data for a tx
     * @param  {JsonRpcTx}          transaction return value of `getTransactionByHash`
     * @param  {TransactionReceipt} receipt
     * @param  {boolean}            isCall
     */
    private _collectMethodsData;
    /**
     * Returns true if there is a contract name associated with an address
     * but method can't be matched to it
     * @param  {String}  name  contract name
     * @param  {String}  input code
     * @return {Boolean}
     */
    private _isProxied;
}
//# sourceMappingURL=collector.d.ts.map