import type { EthereumProvider, HardhatRuntimeEnvironment } from "hardhat/types";
import type { Deployment, GasReporterOptions, MethodData, ContractInfo, MethodDataItem } from '../types';
/**
 * Data store written to by Collector and consumed by output formatters.
 */
export declare class GasData {
    addressCache: {
        [hash: string]: string;
    };
    methods: MethodData;
    deployments: Deployment[];
    codeHashMap: {
        [hash: string]: string;
    };
    provider: EthereumProvider | undefined;
    constructor(methods?: MethodData, deployments?: Deployment[]);
    /**
     * Sets up data structures to store deployments and methods gas usage
     * @param {EthereumProvider}       provider
     * @param {ContractInfo[]}         contracts
     * @returns
     */
    initialize(provider: EthereumProvider, contracts: ContractInfo[]): void;
    /**
     * Calculate gas deltas compared to previous data, if applicable
     * @param  {GasData} previousData previous gas data
     */
    addDeltas(previousData: GasData): void;
    /**
     * Map a contract name to pre-generated hash of the code stored at an address
     * @param  {String} name    contract name
     * @param  {String} address contract address
     */
    trackNameByPreloadedAddress(name: string, address: string, hash: string): void;
    /**
     * Map a contract name to the sha1 hash of the code stored at an address
     * @param  {String} name    contract name
     * @param  {String} address contract address
     */
    trackNameByAddress(name: string, address: string): Promise<void>;
    /**
     * Get the name of the contract stored at contract address
     * @param  {string | null}                 contract address
     * @return {Promse<string | null>}         contract name
     */
    getNameByAddress(address: string | null): Promise<string | null>;
    /**
     * Compares existing contract binaries to the input code for a
     * new deployment transaction and returns the relevant contract.
     * Ignores interfaces.
     * @param  {String}                  input tx.input
     * @return {Deployment | null}       this.deployments entry
     */
    getContractByDeploymentInput(input: string): Deployment | null;
    /**
     * Compares code at an address to the deployedBytecode for all
     * compiled contracts and returns the relevant item.
     * Ignores interfaces.
     * @param  {String} code         result of web3.eth.getCode
     * @return {Deployment | null}   this.deployments entry
     */
    getContractByDeployedBytecode(code: string): Deployment | null;
    /**
     * Returns all contracts with a method matching the requested signature
     * @param  {String}   signature method signature hash
     * @return {MethodDataItem[]}           this.method entries array
     */
    getAllContractsWithMethod(signature: string): MethodDataItem[];
    addressIsCached(address: string | null): boolean;
    resetAddressCache(): void;
    /**
     * Calculates summary and price data for methods and deployments data after it's all
     * been collected
     */
    runAnalysis(hre: HardhatRuntimeEnvironment, options: GasReporterOptions): Promise<void>;
    /**
     * Calculates execution and calldata gas averages, min/max and currency cost for method
     * and deployment data
     * @param {MethodDataItem | Deployment} item
     * @param {GasReporterOptions}          options
     */
    private _processItemData;
    /**
     * Optionally calculates the total currency cost of execution and calldata gas usage
     * @param {number}             executionGas
     * @param {number}             calldataGas
     * @param {GasReporterOptions} options
     * @returns
     */
    private _getCost;
    /**
     * Calculate gas deltas for a given method or deployment item
     * @param  {MethodDataItem | Deployment} prev
     * @param  {MethodDataItem | Deployment} current
     */
    private _calculateDeltas;
}
//# sourceMappingURL=gasData.d.ts.map