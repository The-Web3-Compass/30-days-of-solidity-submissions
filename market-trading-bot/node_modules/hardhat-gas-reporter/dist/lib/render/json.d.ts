import { GasData } from "../gasData";
import { GasReporterOptions, GasReporterOutput } from "../../types";
/**
 * Writes accumulated data and the current options to gasReporterOutput.json so it
 * can be consumed by other tools (CI etc...)
 * @param {GasData}               data
 * @param {GasReporterOptions}    options
 * @param {string}                toolchain
 */
export declare function generateJSONData(data: GasData, options: GasReporterOptions, toolchain?: string): void;
/**
 * Reads previous acccumulated data and options from cache so it can be used to calculate deltas
 * @param {GasReporterOptions} options
 * @returns {GasReporterOptions} previous data and options
 */
export declare function loadJSONCache(options: GasReporterOptions): GasReporterOutput;
//# sourceMappingURL=json.d.ts.map