import type { GasData } from "../gasData";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { GasReporterOptions, JsonRpcTx } from "../../types";
export declare class Resolver {
    unresolvedCalls: number;
    data: GasData;
    hre: HardhatRuntimeEnvironment;
    resolveByProxy: Function;
    constructor(hre: HardhatRuntimeEnvironment, options: GasReporterOptions, data: GasData);
    /**
     * Searches all known contracts for the method signature and returns the first
     * found (if any). Undefined if none
     * @param  {Object} tx          result of web3.eth_getTransaction
     * @return {String}             contract name
     */
    resolveByMethodSignature(tx: JsonRpcTx): string | null;
    /**
     * Tries to match bytecode deployed at address to deployedBytecode listed
     * in artifacts. If found, adds this to the code-hash name mapping and
     * returns name.
     * @param  {String} address contract address
     * @return {String}         contract name
     */
    resolveByDeployedBytecode(address: string | null): Promise<string | null>;
    /**
     * Helper for CustomResolvers which checks the existing contract address cache before
     * trying to resolve by deployed bytecode
     * @param contractAddress
     * @returns
     */
    resolveViaCache(contractAddress: string): Promise<string | null | undefined>;
}
//# sourceMappingURL=index.d.ts.map