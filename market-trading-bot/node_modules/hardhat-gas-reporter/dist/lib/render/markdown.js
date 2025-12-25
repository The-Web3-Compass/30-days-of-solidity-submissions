"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateMarkdownTable = void 0;
const os_1 = require("os");
const markdown_table_1 = __importDefault(require("markdown-table"));
const lodash_1 = __importDefault(require("lodash"));
const units_1 = require("@ethersproject/units");
const constants_1 = require("../../constants");
const ui_1 = require("../../utils/ui");
/**
 * Generates a gas statistics table in markdown format.
 * Based on Alan Lu's (github.com/cag) stats for Gnosis
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasData}                   data
 * @param  {GasReporterOptions}        options
 * @param  {string}                    toolchain
 */
function generateMarkdownTable(hre, data, options, toolchain) {
    let gasAverageTitle = ["Avg"];
    let alignment;
    const addedContracts = [];
    if (options.L2 === "optimism" || options.L2 === "base") {
        gasAverageTitle = ["L2 Avg (Exec)", "L1 Avg (Data)"];
    }
    if (options.L2 === "arbitrum") {
        gasAverageTitle = ["L2 Avg (Exec)", "L1 Avg (Bytes)"];
    }
    // ---------------------------------------------------------------------------------------------
    // Assemble section: Build options
    // ---------------------------------------------------------------------------------------------
    let gasPrices;
    let l1gwei;
    let l2gwei;
    let l1GweiBlobBaseFee;
    const { network, currency, nonZeroMsg, intrinsicMsg } = (0, ui_1.getCommonTableVals)(options);
    let tokenPrice = "-";
    let rate;
    let token;
    if (options.tokenPrice && options.gasPrice) {
        ({
            l1gwei,
            l2gwei,
            l1GweiBlobBaseFee,
            rate,
            token
        } = (0, ui_1.getCommonTableVals)(options));
        gasPrices = (options.L2)
            ? (options.L2 === "arbitrum")
                ? [
                    [`L1 Base Fee Per Byte`, `${options.baseFeePerByte} gwei`],
                    [`L2 Gas Price`, `${l2gwei} gwei`]
                ]
                : [
                    [`L1 Base Fee`, `${options.baseFee} gwei`],
                    [`L1 Blob Base Fee`, `${l1GweiBlobBaseFee} gwei`],
                    [`L2 Gas Price`, `${l2gwei} gwei`]
                ]
            : [[`L1 Gas Price`, `${l1gwei} gwei`]];
        tokenPrice = `${rate} ${currency}/${token}`;
    }
    else {
        gasPrices = [["Gas Price", "-"]];
    }
    const optionsRows = [
        ["**Settings**", "**Value**"],
        ["Solidity: version", options.solcInfo.version],
        ["Solidity: optimized", options.solcInfo.optimizer],
        ["Solidity: runs", options.solcInfo.runs.toString()],
        ["Solidity: viaIR", options.solcInfo.viaIR.toString()],
        ["Block Limit", (0, units_1.commify)(options.blockGasLimit)],
        ...gasPrices,
        ["Token Price", tokenPrice],
        ["Network", network],
        ["Toolchain", toolchain]
    ];
    const keyRows = [
        ["**Symbol**", "**Meaning**"],
        [(0, ui_1.markdownBold)(constants_1.UNICODE_CIRCLE), intrinsicMsg],
        [(0, ui_1.markdownBold)(constants_1.UNICODE_TRIANGLE), nonZeroMsg]
    ];
    const optionsTable = (0, markdown_table_1.default)(optionsRows);
    const keyTable = (0, markdown_table_1.default)(keyRows, { align: ["c", "l"] });
    // ---------------------------------------------------------------------------------------------
    // Assemble section: methods
    // ---------------------------------------------------------------------------------------------
    const methodRows = [];
    const methodHeader = [
        "",
        "Min",
        "Max",
        ...gasAverageTitle,
        "Calls",
        `${currency} avg`
    ];
    lodash_1.default.forEach(data.methods, (method) => {
        if (!method)
            return;
        const stats = {};
        if (method.gasData.length > 0) {
            stats.executionGasAverage = (0, units_1.commify)(method.executionGasAverage);
            stats.cost = (method.cost === undefined) ? "-" : method.cost;
            if (method.calldataGasAverage !== undefined) {
                stats.calldataGasAverage = (method.calldataGasAverage === 0)
                    ? "-"
                    : (0, units_1.commify)(method.calldataGasAverage);
            }
            ;
        }
        else {
            stats.executionGasAverage = "-";
            stats.cost = "-";
        }
        if ((0, ui_1.costIsBelowPrecision)(stats.cost, options)) {
            stats.cost = (0, ui_1.markdownBold)(constants_1.UNICODE_TRIANGLE);
        }
        if (method.min && method.max) {
            const uniform = (method.min === method.max);
            stats.min = uniform ? "-" : (0, units_1.commify)(method.min);
            stats.max = uniform ? "-" : (0, units_1.commify)(method.max);
        }
        stats.numberOfCalls = method.numberOfCalls.toString();
        const fnName = options.showMethodSig ? method.fnSig : method.method;
        const indented = (method.isCall)
            ? (0, ui_1.indentMarkdownWithSymbol)(fnName, (0, ui_1.markdownBold)(constants_1.UNICODE_CIRCLE))
            : (0, ui_1.indentMarkdown)(fnName);
        if (method.numberOfCalls > 0) {
            // Contracts name row
            if (!addedContracts.includes(method.contract)) {
                addedContracts.push(method.contract);
                const titleSection = {
                    row: [
                        (0, ui_1.entitleMarkdown)(method.contract),
                        " ",
                        " ",
                        " ",
                        " ",
                        " ",
                    ],
                    contractName: method.contract,
                    methodName: "0"
                };
                methodRows.push(titleSection);
            }
            const averages = (options.L2 !== undefined)
                ? [stats.executionGasAverage, stats.calldataGasAverage]
                : [stats.executionGasAverage];
            // Method row
            const methodSection = {
                row: [
                    indented,
                    stats.min,
                    stats.max,
                    ...averages,
                    method.numberOfCalls.toString(),
                    stats.cost.toString()
                ],
                contractName: method.contract,
                methodName: fnName
            };
            methodRows.push(methodSection);
        }
    });
    methodRows.sort((a, b) => {
        const contractName = a.contractName.localeCompare(b.contractName);
        const methodName = a.methodName.localeCompare(b.methodName);
        return contractName || methodName;
    });
    const rows = methodRows.map(val => val.row);
    alignment = { align: ["l", "r", "r", "r", "r", "r", "r", "r"] };
    rows.unshift(methodHeader);
    const methodTable = (0, markdown_table_1.default)(rows, alignment);
    // ---------------------------------------------------------------------------------------------
    // Assemble section: deployments
    // ---------------------------------------------------------------------------------------------
    const deployRows = [];
    const deployHeader = [
        "",
        "Min",
        "Max ",
        ...gasAverageTitle,
        "Block %",
        `${currency} avg`
    ];
    // Alphabetize contract names
    data.deployments.sort((a, b) => a.name.localeCompare(b.name));
    data.deployments.forEach(deployment => {
        const stats = {};
        if (!deployment.gasData.length)
            return;
        stats.cost = (deployment.cost === undefined) ? "-" : deployment.cost;
        if (deployment.min && deployment.max) {
            const uniform = deployment.min === deployment.max;
            stats.min = uniform ? "-" : (0, units_1.commify)(deployment.min);
            stats.max = uniform ? "-" : (0, units_1.commify)(deployment.max);
        }
        stats.percent = deployment.percent;
        stats.executionGasAverage = (0, units_1.commify)(deployment.executionGasAverage);
        if (deployment.calldataGasAverage !== undefined) {
            stats.calldataGasAverage = (0, units_1.commify)(deployment.calldataGasAverage);
        }
        ;
        const averages = (options.L2 !== undefined)
            ? [stats.executionGasAverage, stats.calldataGasAverage]
            : [stats.executionGasAverage];
        if ((0, ui_1.costIsBelowPrecision)(stats.cost, options)) {
            stats.cost = (0, ui_1.markdownBold)(constants_1.UNICODE_TRIANGLE);
        }
        const section = [
            (0, ui_1.entitleMarkdown)(deployment.name),
            stats.min,
            stats.max,
            ...averages,
            `${stats.percent} %`,
            stats.cost
        ];
        deployRows.push(section);
    });
    alignment = { align: ["l", "r", "r", "r", "r", "r", "r"] };
    deployRows.unshift(deployHeader);
    const deployTable = (0, markdown_table_1.default)(deployRows, alignment);
    // ---------------------------------------------------------------------------------------------
    // Final assembly
    // ---------------------------------------------------------------------------------------------
    const optionsTitle = `## Solidity and Network Config${os_1.EOL}`;
    const methodTitle = `## Methods${os_1.EOL}`;
    const deployTitle = `## Deployments${os_1.EOL}`;
    const md = `${methodTitle +
        keyTable + os_1.EOL + os_1.EOL +
        methodTable}\n\n${deployTitle}${deployTable}\n\n${optionsTitle}${optionsTable}\n\n`;
    // ---------------------------------------------------------------------------------------------
    // Finish
    // ---------------------------------------------------------------------------------------------
    return md;
}
exports.generateMarkdownTable = generateMarkdownTable;
//# sourceMappingURL=markdown.js.map