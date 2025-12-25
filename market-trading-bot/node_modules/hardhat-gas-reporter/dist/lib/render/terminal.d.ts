import { HardhatRuntimeEnvironment } from "hardhat/types";
import { GasData } from "../gasData";
import { GasReporterOptions } from "../../types";
/**
 * Generates a gas statistics text table formatted for terminal or file.
 * Based on Alan Lu's (github.com/cag) stats for Gnosis
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasData}                   data
 * @param  {GasReporterOptions}        options
 * @param  {string}                    string
 */
export declare function generateTerminalTextTable(hre: HardhatRuntimeEnvironment, data: GasData, options: GasReporterOptions, toolchain: string): string;
//# sourceMappingURL=terminal.d.ts.map