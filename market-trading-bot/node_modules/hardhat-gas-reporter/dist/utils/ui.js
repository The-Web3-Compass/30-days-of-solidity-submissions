"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCommonTableVals = exports.reportMerge = exports.warnDeprecatedTask = exports.warnParallel = exports.warnReportFormat = exports.warnEthers = exports.warnUnsupportedChainConfig = exports.warnBaseFeePerByteRemoteCallFailed = exports.warnBlobBaseFeeRemoteCallFailed = exports.warnBaseFeeRemoteCallFailed = exports.warnGasPriceRemoteCallFailed = exports.warnCMCRemoteCallFailed = exports.costIsBelowPrecision = exports.getSmallestPrecisionVal = exports.renderWithGasDelta = exports.markdownItalic = exports.markdownBold = exports.entitleMarkdown = exports.indentMarkdownWithSymbol = exports.indentTextWithSymbol = exports.indentMarkdown = exports.indentText = void 0;
const chalk_1 = __importDefault(require("chalk"));
const os_1 = require("os");
const units_1 = require("@ethersproject/units");
const constants_1 = require("../constants");
const log = console.log;
function indentText(val) {
    return `    ${val}`;
}
exports.indentText = indentText;
function indentMarkdown(val) {
    return `       *${val}*`;
}
exports.indentMarkdown = indentMarkdown;
function indentTextWithSymbol(val, symbol) {
    return ` ${symbol}  ${val}`;
}
exports.indentTextWithSymbol = indentTextWithSymbol;
function indentMarkdownWithSymbol(val, symbol) {
    return `    ${symbol}  *${val}*`;
}
exports.indentMarkdownWithSymbol = indentMarkdownWithSymbol;
function entitleMarkdown(val) {
    return `**${val}**`;
}
exports.entitleMarkdown = entitleMarkdown;
function markdownBold(val) {
    return `**${val}**`;
}
exports.markdownBold = markdownBold;
function markdownItalic(val) {
    return `*${val}*`;
}
exports.markdownItalic = markdownItalic;
function renderWithGasDelta(val, delta, withColor) {
    if (delta === 0)
        return val;
    let deltaString = (0, units_1.commify)(delta);
    if (withColor) {
        deltaString = delta > 0 ? chalk_1.default.redBright(`+${deltaString}`) : chalk_1.default.green(`${deltaString}`);
    }
    else {
        deltaString = delta > 0 ? `+${deltaString}` : `${deltaString}`;
    }
    return `${val} ${deltaString}`;
}
exports.renderWithGasDelta = renderWithGasDelta;
function getSmallestPrecisionVal(precision) {
    let start = ".";
    for (let i = 0; i < precision - 1; i++) {
        start += "0";
    }
    start += "1";
    return parseFloat(start);
}
exports.getSmallestPrecisionVal = getSmallestPrecisionVal;
function costIsBelowPrecision(_cost, options) {
    const cost = parseFloat(_cost);
    if (isNaN(cost))
        return false;
    return cost < getSmallestPrecisionVal(options.currencyDisplayPrecision);
}
exports.costIsBelowPrecision = costIsBelowPrecision;
const startWarning = chalk_1.default.yellow.bold(`>>>>> WARNING (hardhat-gas-reporter plugin) <<<<<<`);
function remoteCallEndMessage(err) {
    return `${chalk_1.default.bold(`Error was: `)}${chalk_1.default.red(err.message)}${os_1.EOL}${chalk_1.default.bold(`Reported price data is missing or incorrect`)}${os_1.EOL}${chalk_1.default.blue(`* Being rate limited? See the Etherscan API key options in the docs.`)}${os_1.EOL}${chalk_1.default.blue(`* Set the "offline" option to "true" to suppress these warnings`)}${os_1.EOL}${chalk_1.default.yellow.bold(`>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>`)}${os_1.EOL}`;
}
;
function warnCMCRemoteCallFailed(err, url) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to get token price from ${url}`)}${os_1.EOL}${remoteCallEndMessage(err)}`;
}
exports.warnCMCRemoteCallFailed = warnCMCRemoteCallFailed;
function warnGasPriceRemoteCallFailed(err, url) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to get gas price from ${url}`)}${os_1.EOL}${remoteCallEndMessage(err)}`;
}
exports.warnGasPriceRemoteCallFailed = warnGasPriceRemoteCallFailed;
function warnBaseFeeRemoteCallFailed(err, url) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to get L1 base fee from ${url}`)}${os_1.EOL}${remoteCallEndMessage(err)}`;
}
exports.warnBaseFeeRemoteCallFailed = warnBaseFeeRemoteCallFailed;
function warnBlobBaseFeeRemoteCallFailed(err) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to fetch blob base fee, defaulting to 10 gwei.`)}${os_1.EOL}${chalk_1.default.bold(`Try setting an API key for the "L2Etherscan" option.`)}${os_1.EOL}${remoteCallEndMessage(err)}`;
}
exports.warnBlobBaseFeeRemoteCallFailed = warnBlobBaseFeeRemoteCallFailed;
function warnBaseFeePerByteRemoteCallFailed(err) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to fetch Arbitrum L1 base fee data, defaulting to 20 gwei.`)}${os_1.EOL}${chalk_1.default.bold(`Try setting an API key for the "L2Etherscan" option.`)}${os_1.EOL}${remoteCallEndMessage(err)}`;
}
exports.warnBaseFeePerByteRemoteCallFailed = warnBaseFeePerByteRemoteCallFailed;
function warnUnsupportedChainConfig(chain) {
    return `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Unsupported "L1" or "L2" setting: "${chain}" encountered while configuring ` +
        `price data urls. Please set the necessary override options yourself ` +
        `or use one of the supported auto-config L1 or L2 values (see docs).`)}${os_1.EOL}${remoteCallEndMessage({ message: "" })}`;
}
exports.warnUnsupportedChainConfig = warnUnsupportedChainConfig;
/**
 * Message for un-parseable ABI (ethers)
 * @param  {string} name contract name
 * @param  {any} err
 * @return {void}
 */
function warnEthers(name, err) {
    const msg = `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to parse ABI for contract: "${name}". (Its method data will not be collected).`)}${os_1.EOL}Please report the error below with the source that caused it to ` +
        `github.com/cgewecke/hardhat-gas-reporter${os_1.EOL}${chalk_1.default.yellow(`>>>>>>>>>>>>>>>>>>>>`)}${os_1.EOL}${chalk_1.default.red(`${err}`)}`;
    log(msg);
}
exports.warnEthers = warnEthers;
/**
 * Message invalid report formats
 * @param  {string} name report format
 * @return {void}
 */
function warnReportFormat(name) {
    const msg = `${startWarning}${os_1.EOL}${chalk_1.default.bold(`Failed to generate gas report for format: "${name}". The available formats are: `)}${os_1.EOL}${chalk_1.default.green(`> "${constants_1.TABLE_NAME_TERMINAL}"`)}${os_1.EOL}${chalk_1.default.green(`> "${constants_1.TABLE_NAME_MARKDOWN}"`)}${os_1.EOL}${chalk_1.default.green(`> "${constants_1.TABLE_NAME_LEGACY}"`)}${os_1.EOL}${chalk_1.default.yellow(`>>>>>>>>>>>>>>>>>>>>`)}${os_1.EOL}`;
    log(msg);
}
exports.warnReportFormat = warnReportFormat;
/**
 * Message for `--parallel` disabling gas reporter
 * @return {void}
 */
function warnParallel() {
    const msg = `${startWarning}${os_1.EOL}${chalk_1.default.bold("Gas reporting has been skipped because plugin `hardhat-gas-reporter` " +
        "does not support the --parallel flag.")}${os_1.EOL}${chalk_1.default.yellow(`>>>>>>>>>>>>>>>>>>>>`)}${os_1.EOL}`;
    log(msg);
}
exports.warnParallel = warnParallel;
/**
 * Message for deprecated task names
 * @return {void}
 */
function warnDeprecatedTask(newName) {
    const msg = `${startWarning}${os_1.EOL}${chalk_1.default.bold(`This gas reporter task has been renamed to "${chalk_1.default.green(newName)}"`)}${os_1.EOL}${chalk_1.default.yellow(`>>>>>>>>>>>>>>>>>>>>`)}${os_1.EOL}`;
    log(msg);
}
exports.warnDeprecatedTask = warnDeprecatedTask;
function reportMerge(files, output) {
    let filesList = "";
    files.forEach((f) => filesList += chalk_1.default.yellow(`  - ${f}`) + os_1.EOL);
    const msg = `${chalk_1.default.bold(`Merging ${files.length} input files:`)}${os_1.EOL}${filesList}${os_1.EOL}${chalk_1.default.bold("Output: ")}${os_1.EOL}  - ${chalk_1.default.green(output)}${os_1.EOL}`;
    log(msg);
}
exports.reportMerge = reportMerge;
/**
 * Gets L1 / L2 variables shared between tables
 * @param options
 * @returns
 */
function getCommonTableVals(options) {
    const usingL1 = options.L2 === undefined;
    let l2BaseFeeNote = "(baseFee)";
    let l1GweiForL2 = options.baseFee;
    let l1GweiBlobBaseFee = options.blobBaseFee;
    if (options.L2 === "arbitrum") {
        l2BaseFeeNote = "(baseFeePerByte)";
        l1GweiForL2 = options.baseFeePerByte;
    }
    let token = "";
    let l1gwei = (usingL1) ? options.gasPrice : l1GweiForL2;
    let l2gwei = (usingL1) ? "" : options.gasPrice;
    const l1gweiNote = (usingL1) ? "" : l2BaseFeeNote;
    const l2gweiNote = (usingL1) ? "" : "(gasPrice)";
    const network = (usingL1) ? options.L1.toUpperCase() : options.L2.toUpperCase();
    const rate = (options.tokenPrice)
        ? parseFloat(options.tokenPrice.toString()).toFixed(2)
        : "-";
    const currency = (options.currency)
        ? `${options.currency.toLowerCase()}`
        : "-";
    if (options.token) {
        token = `${options.token.toLowerCase()}`;
    }
    // Truncate subzero gas prices to 5 decimal precision
    if (typeof l1gwei === "number" && l1gwei < 1) {
        l1gwei = parseFloat(l1gwei.toString()).toFixed(constants_1.DEFAULT_GAS_PRICE_PRECISION);
    }
    if (typeof l2gwei === "number" && l2gwei < 1) {
        l2gwei = parseFloat(l2gwei.toString()).toFixed(constants_1.DEFAULT_GAS_PRICE_PRECISION);
    }
    if (typeof l1GweiBlobBaseFee === "number" && l1GweiBlobBaseFee < 1) {
        l1GweiBlobBaseFee = parseFloat(l1GweiBlobBaseFee.toString()).toFixed(constants_1.DEFAULT_GAS_PRICE_PRECISION);
    }
    const nonZeroMsg = "Cost was non-zero but below the precision setting for the currency display (see options)";
    const intrinsicMsg = "Execution gas for this method does not include intrinsic gas overhead ";
    return {
        l1gwei,
        l2gwei,
        l1gweiNote,
        l2gweiNote,
        l1GweiBlobBaseFee,
        network,
        rate,
        currency,
        token,
        nonZeroMsg,
        intrinsicMsg
    };
}
exports.getCommonTableVals = getCommonTableVals;
//# sourceMappingURL=ui.js.map