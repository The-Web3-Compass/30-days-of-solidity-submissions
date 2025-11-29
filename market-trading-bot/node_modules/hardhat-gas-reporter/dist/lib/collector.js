"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Collector = void 0;
const bytes_1 = require("@ethersproject/bytes");
const sources_1 = require("../utils/sources");
const gas_1 = require("../utils/gas");
const gasData_1 = require("./gasData");
const resolvers_1 = require("./resolvers");
/**
 * Collects gas usage data, associating it with the relevant contracts, methods.
 */
class Collector {
    constructor(hre, options) {
        this.data = new gasData_1.GasData();
        this.options = options;
        this.resolver = new resolvers_1.Resolver(hre, options, this.data);
    }
    /**
     * Method called by the request monitor on the provider to collect deployment
     * and methods gas data
     * @param {JsonRpcTx} transaction [description]
     * @param {TransactionReceipt} receipt     [description]
     */
    async collectTransaction(tx, receipt) {
        if (receipt.contractAddress !== null)
            await this._collectDeploymentsData(tx, receipt);
        else
            await this._collectMethodsData(tx, receipt, false);
    }
    /**
     * Method called by the request monitor on the provider to get gas data for `eth_call`
     * @param {ValidatedRequestArguments}    params.args  of the call
     * @param {number}                       estimate_gas result
     */
    async collectCall(args, gas) {
        const callGas = gas - (0, gas_1.getIntrinsicGas)(args.params[0].data);
        const fakeTx = {
            input: args.params[0].data,
            to: args.params[0].to,
            isCall: true
        };
        const fakeReceipt = {
            gasUsed: (0, bytes_1.hexlify)(callGas)
        };
        await this._collectMethodsData(fakeTx, fakeReceipt, true);
    }
    /**
     * Extracts and stores deployments gas usage data for a tx
     * @param  {JsonRpcTx}          tx       return value of `getTransactionByHash`
     * @param  {TransactionReceipt} receipt
     */
    async _collectDeploymentsData(tx, receipt) {
        const match = this.data.getContractByDeploymentInput(tx.input);
        if (match !== null) {
            await this.data.trackNameByAddress(match.name, receipt.contractAddress);
            const executionGas = (0, gas_1.hexToDecimal)(receipt.gasUsed);
            const calldataGas = (0, gas_1.getCalldataGasForNetwork)(this.options, tx);
            match.gasData.push(executionGas);
            match.callData.push(calldataGas);
        }
    }
    /**
     * Extracts and stores methods gas usage data for a tx
     * @param  {JsonRpcTx}          transaction return value of `getTransactionByHash`
     * @param  {TransactionReceipt} receipt
     * @param  {boolean}            isCall
     */
    async _collectMethodsData(tx, receipt, isCall) {
        let contractName = await this.data.getNameByAddress(tx.to);
        // Case: proxied call
        if (this._isProxied(contractName, tx.input)) {
            contractName = await this.resolver.resolveByProxy(tx);
        }
        // Case: hidden contract factory deployment
        if (contractName === null) {
            contractName = await this.resolver.resolveByDeployedBytecode(tx.to);
        }
        // Case: all else fails, use first match strategy
        if (contractName === null) {
            contractName = this.resolver.resolveByMethodSignature(tx);
        }
        const id = (0, sources_1.getMethodID)(contractName, tx.input);
        if (this.data.methods[id] !== undefined) {
            const executionGas = (this.options.includeIntrinsicGas)
                ? (0, gas_1.hexToDecimal)(receipt.gasUsed)
                : (0, gas_1.getGasSubIntrinsic)(tx.input, (0, gas_1.hexToDecimal)(receipt.gasUsed));
            // If L2 txs have intrinsic turned off, we assume caller
            // is paying the L1 overhead
            const calldataGas = (isCall || !this.options.includeIntrinsicGas)
                ? 0
                : (0, gas_1.getCalldataGasForNetwork)(this.options, tx);
            const intrinsicGas = (0, gas_1.getIntrinsicGas)(tx.input);
            this.data.methods[id].gasData.push(executionGas);
            this.data.methods[id].callData.push(calldataGas);
            this.data.methods[id].intrinsicGas.push(intrinsicGas);
            this.data.methods[id].numberOfCalls += 1;
            this.data.methods[id].isCall = this.data.methods[id].isCall || !this.options.includeIntrinsicGas;
        }
        else {
            this.resolver.unresolvedCalls++;
        }
    }
    /**
     * Returns true if there is a contract name associated with an address
     * but method can't be matched to it
     * @param  {String}  name  contract name
     * @param  {String}  input code
     * @return {Boolean}
     */
    _isProxied(name, input) {
        if (name !== null) {
            return (this.data.methods[(0, sources_1.getMethodID)(name, input)] === undefined);
        }
        return false;
    }
}
exports.Collector = Collector;
//# sourceMappingURL=collector.js.map