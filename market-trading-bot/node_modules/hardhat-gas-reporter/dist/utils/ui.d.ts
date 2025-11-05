import { GasReporterOptions } from "../types";
export declare function indentText(val: string): string;
export declare function indentMarkdown(val: string): string;
export declare function indentTextWithSymbol(val: string, symbol: string): string;
export declare function indentMarkdownWithSymbol(val: string, symbol: string): string;
export declare function entitleMarkdown(val: string): string;
export declare function markdownBold(val: string): string;
export declare function markdownItalic(val: string): string;
export declare function renderWithGasDelta(val: string, delta: number, withColor?: boolean): string;
export declare function getSmallestPrecisionVal(precision: number): number;
export declare function costIsBelowPrecision(_cost: string, options: GasReporterOptions): boolean;
export declare function warnCMCRemoteCallFailed(err: any, url: string): string;
export declare function warnGasPriceRemoteCallFailed(err: any, url: string): string;
export declare function warnBaseFeeRemoteCallFailed(err: any, url: string): string;
export declare function warnBlobBaseFeeRemoteCallFailed(err: any): string;
export declare function warnBaseFeePerByteRemoteCallFailed(err: any): string;
export declare function warnUnsupportedChainConfig(chain: string): string;
/**
 * Message for un-parseable ABI (ethers)
 * @param  {string} name contract name
 * @param  {any} err
 * @return {void}
 */
export declare function warnEthers(name: string, err: any): void;
/**
 * Message invalid report formats
 * @param  {string} name report format
 * @return {void}
 */
export declare function warnReportFormat(name: string | undefined): void;
/**
 * Message for `--parallel` disabling gas reporter
 * @return {void}
 */
export declare function warnParallel(): void;
/**
 * Message for deprecated task names
 * @return {void}
 */
export declare function warnDeprecatedTask(newName: string): void;
export declare function reportMerge(files: string[], output: string): void;
/**
 * Gets L1 / L2 variables shared between tables
 * @param options
 * @returns
 */
export declare function getCommonTableVals(options: GasReporterOptions): {
    l1gwei: string | number;
    l2gwei: string | number;
    l1gweiNote: string;
    l2gweiNote: string;
    l1GweiBlobBaseFee: string | number;
    network: string;
    rate: string;
    currency: string;
    token: string;
    nonZeroMsg: string;
    intrinsicMsg: string;
};
//# sourceMappingURL=ui.d.ts.map