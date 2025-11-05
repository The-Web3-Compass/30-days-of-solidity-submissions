import { GasReporterOptions } from "../types";
/**
 * Fetches gas, base, & blob fee rates from etherscan as well as current market value of
 * network token in nation state currency specified by the options from coinmarketcap
 * (defaults to usd). Sets
 *
 * + options.tokenPrice
 * + options.gasPrice
 * + options.baseFee
 * + options.blobBaseFee
 *
 * ... unless these are already set as constants in the reporter options
 *
 * Returns a list of warnings generated if remote calls fail
 * @param  {GasReporterOptions} options
 */
export declare function setGasAndPriceRates(options: GasReporterOptions): Promise<string[]>;
//# sourceMappingURL=prices.d.ts.map