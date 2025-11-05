import { GasReporterOptions } from "../types";
/**
 * Returns the CMC token symbol for a chain's native token. Uses chain configs below
 * and defers to user overrides
 * @param {GasReporterOptions} options
 * @returns
 */
export declare function getTokenForChain(options: GasReporterOptions): string;
/**
 * Gets Etherscan gasPrice api call url for chain. Attaches L1 or L2 apikey if configured
 * @param {GasReporterOptions} options
 * @returns
 */
export declare function getGasPriceUrlForChain(options: GasReporterOptions): string;
/**
 * Gets Etherscan getBlock api call url for chain. Attaches L1 apikey if configured
 * (THIS IS ALWAYS for L1 data-related fees in the context of L2 execution)
 * @param {GasReporterOptions} options
 * @returns
 */
export declare function getBlockUrlForChain(options: GasReporterOptions): string;
/**
 * Gets Etherscan eth_call api url to read OP Stack GasPriceOracle for blobBaseFee.
 * Attaches apikey if configured. (This fee fetched from L2 contract b/c its the only available place at
 * time of PR - eth_blobBaseFee hasn't been implemented in geth yet)
 * @param {GasReporterOptions} options
 * @returns
 */
export declare function getBlobBaseFeeUrlForChain(options: GasReporterOptions): string;
/**
 * Gets Etherscan eth_call api url to read OP Stack GasPriceOracle for blobBaseFee.
 * Attaches apikey if configured. (This fee fetched from L2 contract b/c its the only available place at
 * time of PR - eth_blobBaseFee hasn't been implemented in geth yet)
 * @param {GasReporterOptions} options
 * @returns
 */
export declare function getBaseFeePerByteUrlForChain(options: GasReporterOptions): string;
/**
 * L1 & L2 chain configurations for fetching gas price and block fee data from Etherscan as well
 * as currency prices from Coinmarketcap
 */
export declare const L1: {
    ethereum: {
        baseUrl: string;
        token: string;
    };
    polygon: {
        baseUrl: string;
        token: string;
    };
    binance: {
        baseUrl: string;
        token: string;
    };
    fantom: {
        baseUrl: string;
        token: string;
    };
    moonbeam: {
        baseUrl: string;
        token: string;
    };
    moonriver: {
        baseUrl: string;
        token: string;
    };
    gnosis: {
        baseUrl: string;
        token: string;
    };
    avalanche: {
        baseUrl: string;
        token: string;
    };
};
export declare const L2: {
    optimism: {
        baseUrl: string;
        gasPriceOracle: string;
        token: string;
    };
    base: {
        baseUrl: string;
        gasPriceOracle: string;
        token: string;
    };
    arbitrum: {
        baseUrl: string;
        gasPriceOracle: string;
        token: string;
    };
};
//# sourceMappingURL=chains.d.ts.map