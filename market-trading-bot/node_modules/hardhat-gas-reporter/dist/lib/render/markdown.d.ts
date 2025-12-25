import { HardhatRuntimeEnvironment } from "hardhat/types";
import { GasData } from "../gasData";
import { GasReporterOptions } from "../../types";
/**
 * Generates a gas statistics table in markdown format.
 * Based on Alan Lu's (github.com/cag) stats for Gnosis
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasData}                   data
 * @param  {GasReporterOptions}        options
 * @param  {string}                    toolchain
 */
export declare function generateMarkdownTable(hre: HardhatRuntimeEnvironment, data: GasData, options: GasReporterOptions, toolchain: string): string;
//# sourceMappingURL=markdown.d.ts.map