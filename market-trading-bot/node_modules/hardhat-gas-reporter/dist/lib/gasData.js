"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GasData = void 0;
const sha1_1 = __importDefault(require("sha1"));
const abi_1 = require("@ethersproject/abi");
const ui_1 = require("../utils/ui");
const sources_1 = require("../utils/sources");
const gas_1 = require("../utils/gas");
/**
 * Data store written to by Collector and consumed by output formatters.
 */
class GasData {
    constructor(methods, deployments) {
        this.addressCache = {};
        this.methods = (methods) ? methods : {};
        this.deployments = (deployments) ? deployments : [];
        this.codeHashMap = {};
    }
    /**
     * Sets up data structures to store deployments and methods gas usage
     * @param {EthereumProvider}       provider
     * @param {ContractInfo[]}         contracts
     * @returns
     */
    initialize(provider, contracts) {
        this.provider = provider;
        for (const item of contracts) {
            const contract = {
                name: item.name,
                bytecode: item.artifact.bytecode,
                deployedBytecode: item.artifact.deployedBytecode,
                gasData: [],
                callData: []
            };
            this.deployments.push(contract);
            if (item.artifact.bytecodeHash) {
                this.trackNameByPreloadedAddress(item.name, item.artifact.address, item.artifact.bytecodeHash);
            }
            // Decode, getMethodIDs
            const methodIDs = {};
            let methods;
            try {
                methods = new abi_1.Interface(item.artifact.abi).functions;
            }
            catch (err) {
                (0, ui_1.warnEthers)(contract.name, err);
                return;
            }
            // Generate sighashes and remap ethers to something similar
            // to abiDecoder.getMethodIDs
            Object.keys(methods).forEach(key => {
                const sighash = (0, sources_1.getHashedFunctionSignature)(key);
                // @ts-ignore
                methodIDs[sighash] = { fnSig: key, ...methods[key] };
            });
            // Create Method Map;
            Object.keys(methodIDs).forEach(key => {
                const isInterface = item.artifact.bytecode === "0x";
                const isCall = methodIDs[key].constant;
                const methodHasName = methodIDs[key].name !== undefined;
                const contractScopedKey = `${contract.name}_${key}`;
                if (methodHasName && !isInterface && !item.excludedMethods.includes(contractScopedKey)) {
                    this.methods[contractScopedKey] = {
                        key,
                        isCall,
                        contract: contract.name,
                        method: methodIDs[key].name,
                        fnSig: methodIDs[key].fnSig,
                        intrinsicGas: [],
                        callData: [],
                        gasData: [],
                        numberOfCalls: 0
                    };
                }
            });
        }
    }
    /**
     * Calculate gas deltas compared to previous data, if applicable
     * @param  {GasData} previousData previous gas data
     */
    addDeltas(previousData) {
        Object.keys(this.methods).forEach(key => {
            if (!previousData.methods[key])
                return;
            const currentMethod = this.methods[key];
            const prevMethod = previousData.methods[key];
            this._calculateDeltas(prevMethod, currentMethod);
        });
        this.deployments.forEach((currentDeployment) => {
            const prevDeployment = previousData.deployments.find((d) => d.name === currentDeployment.name);
            if (!prevDeployment)
                return;
            this._calculateDeltas(prevDeployment, currentDeployment);
        });
    }
    /**
     * Map a contract name to pre-generated hash of the code stored at an address
     * @param  {String} name    contract name
     * @param  {String} address contract address
     */
    trackNameByPreloadedAddress(name, address, hash) {
        if (this.addressIsCached(address))
            return;
        this.codeHashMap[hash] = name;
        this.addressCache[address] = name;
    }
    /**
     * Map a contract name to the sha1 hash of the code stored at an address
     * @param  {String} name    contract name
     * @param  {String} address contract address
     */
    async trackNameByAddress(name, address) {
        if (this.addressIsCached(address))
            return;
        const code = await this.provider.send("eth_getCode", [address, "latest"]);
        const hash = code ? (0, sha1_1.default)(code) : null;
        this.addressCache[address] = name;
        if (hash !== null)
            this.codeHashMap[hash] = name;
    }
    /**
     * Get the name of the contract stored at contract address
     * @param  {string | null}                 contract address
     * @return {Promse<string | null>}         contract name
     */
    async getNameByAddress(address) {
        if (!address)
            return null;
        if (this.addressIsCached(address)) {
            return this.addressCache[address];
        }
        const code = await this.provider.send("eth_getCode", [address, "latest"]);
        const hash = code ? (0, sha1_1.default)(code) : null;
        return (hash !== null) ? this.codeHashMap[hash] : null;
    }
    /**
     * Compares existing contract binaries to the input code for a
     * new deployment transaction and returns the relevant contract.
     * Ignores interfaces.
     * @param  {String}                  input tx.input
     * @return {Deployment | null}       this.deployments entry
     */
    getContractByDeploymentInput(input) {
        if (!input)
            return null;
        const matches = this.deployments.filter(item => (0, sources_1.matchBinaries)(input, item.bytecode));
        // Filter interfaces
        if (matches && (matches.length > 0)) {
            const match = matches.find(item => item.deployedBytecode !== "0x");
            return (match !== undefined) ? match : null;
        }
        else {
            return null;
        }
    }
    /**
     * Compares code at an address to the deployedBytecode for all
     * compiled contracts and returns the relevant item.
     * Ignores interfaces.
     * @param  {String} code         result of web3.eth.getCode
     * @return {Deployment | null}   this.deployments entry
     */
    getContractByDeployedBytecode(code) {
        if (!code)
            return null;
        const matches = this.deployments.filter(item => (0, sources_1.matchBinaries)(code, item.deployedBytecode));
        // Filter interfaces
        if (matches && (matches.length > 0)) {
            const match = matches.find(item => item.deployedBytecode !== "0x");
            return (match !== undefined) ? match : null;
        }
        else {
            return null;
        }
    }
    /**
     * Returns all contracts with a method matching the requested signature
     * @param  {String}   signature method signature hash
     * @return {MethodDataItem[]}           this.method entries array
     */
    getAllContractsWithMethod(signature) {
        return Object.values(this.methods).filter((el) => el.key === signature);
    }
    addressIsCached(address) {
        if (address === null)
            return false;
        return Object.keys(this.addressCache).includes(address);
    }
    resetAddressCache() {
        this.addressCache = {};
    }
    /**
     * Calculates summary and price data for methods and deployments data after it's all
     * been collected
     */
    async runAnalysis(hre, options) {
        const block = await hre.network.provider.send("eth_getBlockByNumber", ["latest", false]);
        const blockGasLimit = parseInt(block.gasLimit);
        let methodsExecutionTotal = 0;
        let methodsCalldataTotal = 0;
        let deploymentsExecutionTotal = 0;
        let deploymentsCalldataTotal = 0;
        /* Methods */
        for (const key of Object.keys(this.methods)) {
            const method = this.methods[key];
            if (method.gasData.length > 0) {
                this._processItemData(method, options);
                methodsExecutionTotal += method.executionGasAverage;
                methodsCalldataTotal += method.calldataGasAverage;
            }
        }
        /* Deployments */
        for (const deployment of this.deployments) {
            if (deployment.gasData.length !== 0) {
                this._processItemData(deployment, options);
                deployment.percent = (0, gas_1.gasToPercentOfLimit)(deployment.executionGasAverage, blockGasLimit);
                deploymentsExecutionTotal += deployment.executionGasAverage;
                deploymentsCalldataTotal += deployment.calldataGasAverage;
            }
        }
        hre.__hhgrec.blockGasLimit = blockGasLimit;
        hre.__hhgrec.methodsTotalGas = methodsExecutionTotal;
        hre.__hhgrec.deploymentsTotalGas = deploymentsExecutionTotal;
        hre.__hhgrec.methodsTotalCost = this._getCost(methodsExecutionTotal, methodsCalldataTotal, options);
        hre.__hhgrec.deploymentsTotalCost = this._getCost(deploymentsExecutionTotal, deploymentsCalldataTotal, options);
    }
    /**
     * Calculates execution and calldata gas averages, min/max and currency cost for method
     * and deployment data
     * @param {MethodDataItem | Deployment} item
     * @param {GasReporterOptions}          options
     */
    _processItemData(item, options) {
        const executionTotal = item.gasData.reduce((acc, datum) => acc + datum, 0);
        item.executionGasAverage = Math.round(executionTotal / item.gasData.length);
        const calldataTotal = item.callData.reduce((acc, datum) => acc + datum, 0);
        item.calldataGasAverage = Math.round(calldataTotal / item.gasData.length);
        item.cost = this._getCost(item.executionGasAverage, item.calldataGasAverage, options);
        const sortedData = item.gasData.sort((a, b) => a - b);
        item.min = sortedData[0];
        item.max = sortedData[sortedData.length - 1];
    }
    /**
     * Optionally calculates the total currency cost of execution and calldata gas usage
     * @param {number}             executionGas
     * @param {number}             calldataGas
     * @param {GasReporterOptions} options
     * @returns
     */
    _getCost(executionGas, calldataGas, options) {
        return (options.tokenPrice && options.gasPrice)
            ? (0, gas_1.gasToCost)(executionGas, calldataGas, options)
            : undefined;
    }
    /**
     * Calculate gas deltas for a given method or deployment item
     * @param  {MethodDataItem | Deployment} prev
     * @param  {MethodDataItem | Deployment} current
     */
    _calculateDeltas(prev, current) {
        if (current.min !== undefined && prev.min !== undefined) {
            current.minDelta = current.min - prev.min;
        }
        if (current.max !== undefined && prev.max !== undefined) {
            current.maxDelta = current.max - prev.max;
        }
        if (current.executionGasAverage !== undefined && prev.executionGasAverage !== undefined) {
            current.executionGasAverageDelta = current.executionGasAverage - prev.executionGasAverage;
        }
        if (current.calldataGasAverage !== undefined && prev.calldataGasAverage !== undefined) {
            current.calldataGasAverageDelta = current.calldataGasAverage - prev.calldataGasAverage;
        }
    }
}
exports.GasData = GasData;
//# sourceMappingURL=gasData.js.map