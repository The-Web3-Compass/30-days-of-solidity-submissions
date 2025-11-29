import type { GasData } from "../gasData";
import { HardhatRuntimeEnvironment as HRE } from "hardhat/types";
import { GasReporterOptions } from "../../types";
/**
 * Table format selector
 * @param {HardhatRuntimeEnvironment} hre
 * @param {GasData}                   data
 * @param {GasReporterOptions}        options
 * @param {string}                    toolchain
 * @returns {string}                  table
 */
export declare function getTableForFormat(hre: HRE, data: GasData, options: GasReporterOptions, toolchain?: string): string;
/**
 * Manages table rendering and file saving
 * @param {HardhatRuntimeEnvironment} hre
 * @param {GasReporterOptions}        options
 * @param {string[]}                  warnings
 * @param {string}                    toolchain
 */
export declare function render(hre: HRE, options: GasReporterOptions, warnings: string[], toolchain?: string): void;
//# sourceMappingURL=index.d.ts.map