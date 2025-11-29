import { EthereumProvider, HardhatRuntimeEnvironment } from "hardhat/types";
import { RemoteContract, ContractInfo, GasReporterOptions } from "../types";
/**
 * Fetches remote bytecode at address and hashes it so these addresses can be
 * added to the tracking in the collector
 * @param  {EGRAsyncApiProvider}   provider
 * @param  {RemoteContract[] = []} remoteContracts
 * @return {Promise<RemoteContract[]>}
 */
export declare function getResolvedRemoteContracts(provider: EthereumProvider, remoteContracts?: RemoteContract[]): Promise<RemoteContract[]>;
/**
 * Loads and processes artifacts
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasReporterOptions[]}      options
 * @return {ContractInfo[]}
 */
export declare function getContracts(hre: HardhatRuntimeEnvironment, options: GasReporterOptions): Promise<ContractInfo[]>;
//# sourceMappingURL=artifacts.d.ts.map