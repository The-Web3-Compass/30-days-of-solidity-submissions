import { HardhatRuntimeEnvironment } from "hardhat/types";
import { GasReporterOptions } from "../../types";
import { GasData } from "../gasData";
/**
 * LEGACY ONLY
 * IGNORE THIS FORMAT WHEN ADDING INFO TO TABLES (UNLESS BUG FIXING)
 */
/**
 * Generates a gas statistics text table formatted for terminal or file.
 * Based on Alan Lu's (github.com/cag) stats for Gnosis
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasData}                   data
 * @param  {GasReporterOptions}        options
 */
export declare function generateLegacyTextTable(hre: HardhatRuntimeEnvironment, data: GasData, options: GasReporterOptions): string;
//# sourceMappingURL=legacy.d.ts.map