"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateLegacyTextTable = void 0;
const chalk_1 = __importDefault(require("chalk"));
const lodash_1 = __importDefault(require("lodash"));
const cli_table3_1 = __importDefault(require("cli-table3"));
const units_1 = require("@ethersproject/units");
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
function generateLegacyTextTable(hre, data, options) {
    let optionalColor;
    if (options.noColors || options.outputFile !== undefined) {
        chalk_1.default.level = 0;
    }
    else {
        chalk_1.default.level = 1;
    }
    if (options.darkMode) {
        optionalColor = chalk_1.default.cyan;
    }
    else {
        optionalColor = chalk_1.default.grey;
    }
    // ---------------------------------------------------------------------------------------------
    // Assemble section: methods
    // ---------------------------------------------------------------------------------------------
    const methodRows = [];
    lodash_1.default.forEach(data.methods, (method) => {
        if (!method)
            return;
        const stats = {};
        if (method.gasData.length > 0) {
            stats.executionGasAverage = (0, units_1.commify)(method.executionGasAverage);
            stats.cost = (method.cost === undefined) ? chalk_1.default.grey("-") : method.cost;
        }
        else {
            stats.executionGasAverage = chalk_1.default.grey("-");
            stats.cost = chalk_1.default.grey("-");
        }
        if (method.min && method.max) {
            const uniform = (method.min === method.max);
            stats.min = uniform ? chalk_1.default.grey("-") : chalk_1.default.cyan((0, units_1.commify)(method.min));
            stats.max = uniform ? chalk_1.default.grey("-") : chalk_1.default.red((0, units_1.commify)(method.max));
        }
        stats.numberOfCalls = optionalColor(method.numberOfCalls.toString());
        const fnName = options.showMethodSig ? method.fnSig : method.method;
        if (options.showUncalledMethods || method.numberOfCalls > 0) {
            const section = [];
            section.push(optionalColor.bold(method.contract));
            section.push(fnName);
            section.push({ hAlign: "right", content: stats.min });
            section.push({ hAlign: "right", content: stats.max });
            section.push({ hAlign: "right", content: stats.executionGasAverage });
            section.push({ hAlign: "right", content: stats.numberOfCalls });
            section.push({
                hAlign: "right",
                content: chalk_1.default.green(stats.cost.toString())
            });
            methodRows.push(section);
        }
    });
    // ---------------------------------------------------------------------------------------------
    // Assemble section: deployments
    // ---------------------------------------------------------------------------------------------
    const deployRows = [];
    // Alphabetize contract names
    data.deployments.sort((a, b) => a.name.localeCompare(b.name));
    data.deployments.forEach(deployment => {
        const stats = {};
        if (deployment.gasData.length === 0)
            return;
        stats.cost = (deployment.cost === undefined) ? chalk_1.default.grey("-") : deployment.cost;
        if (deployment.min && deployment.max) {
            const uniform = deployment.min === deployment.max;
            stats.min = uniform ? chalk_1.default.grey("-") : chalk_1.default.cyan((0, units_1.commify)(deployment.min));
            stats.max = uniform ? chalk_1.default.grey("-") : chalk_1.default.red((0, units_1.commify)(deployment.max));
        }
        const section = [];
        section.push({ hAlign: "left", colSpan: 2, content: deployment.name });
        section.push({ hAlign: "right", content: stats.min });
        section.push({ hAlign: "right", content: stats.max });
        section.push({ hAlign: "right", content: (0, units_1.commify)(deployment.executionGasAverage) });
        section.push({
            hAlign: "right",
            content: optionalColor(`${deployment.percent} %`)
        });
        section.push({
            hAlign: "right",
            content: chalk_1.default.green(stats.cost.toString())
        });
        deployRows.push(section);
    });
    // ---------------------------------------------------------------------------------------------
    // Assemble section: headers
    // ---------------------------------------------------------------------------------------------
    // Configure indentation for RTD
    const leftPad = options.rst ? "  " : "";
    // Format table
    const table = new cli_table3_1.default({
        style: { head: [], border: [], "padding-left": 2, "padding-right": 2 },
        chars: {
            mid: "·",
            "top-mid": "|",
            "left-mid": `${leftPad}·`,
            "mid-mid": "|",
            "right-mid": "·",
            left: `${leftPad}|`,
            "top-left": `${leftPad}·`,
            "top-right": "·",
            "bottom-left": `${leftPad}·`,
            "bottom-right": "·",
            middle: "·",
            top: "-",
            bottom: "-",
            "bottom-mid": "|"
        }
    });
    // Format and load methods metrics
    const title = [
        {
            hAlign: "center",
            colSpan: 2,
            content: optionalColor.bold(`Solc version: ${options.solcInfo.version}`)
        },
        {
            hAlign: "center",
            colSpan: 2,
            content: optionalColor.bold(`Optimizer enabled: ${options.solcInfo.optimizer}`)
        },
        {
            hAlign: "center",
            colSpan: 1,
            content: optionalColor.bold(`Runs: ${options.solcInfo.runs}`)
        },
        {
            hAlign: "center",
            colSpan: 2,
            content: optionalColor.bold(`Block limit: ${(0, units_1.commify)(options.blockGasLimit)} gas`)
        }
    ];
    let methodSubtitle;
    if (options.tokenPrice && options.gasPrice) {
        const gwei = options.gasPrice;
        const rate = parseFloat(options.tokenPrice.toString()).toFixed(2);
        const currency = `${options.currency.toLowerCase()}`;
        const token = `${options.token.toLowerCase()}`;
        methodSubtitle = [
            { hAlign: "left", colSpan: 2, content: chalk_1.default.green.bold("Methods") },
            {
                hAlign: "center",
                colSpan: 3,
                content: chalk_1.default.cyan.bold(`${gwei} gwei/gas`)
            },
            {
                hAlign: "center",
                colSpan: 2,
                content: chalk_1.default.red.bold(`${rate} ${currency}/${token}`)
            }
        ];
    }
    else {
        methodSubtitle = [
            { hAlign: "left", colSpan: 7, content: chalk_1.default.green.bold("Methods") }
        ];
    }
    const header = [
        chalk_1.default.bold("Contract"),
        chalk_1.default.bold("Method"),
        chalk_1.default.green("Min"),
        chalk_1.default.green("Max"),
        chalk_1.default.green("Avg"),
        chalk_1.default.bold("# calls"),
        chalk_1.default.bold(`${options.currency.toLowerCase()} (avg)`)
    ];
    // ---------------------------------------------------------------------------------------------
    // Final assembly
    // ---------------------------------------------------------------------------------------------
    table.push(title);
    table.push(methodSubtitle);
    table.push(header);
    methodRows.sort((a, b) => {
        const contractName = a[0].localeCompare(b[0]);
        const methodName = a[1].localeCompare(b[1]);
        return contractName || methodName;
    });
    methodRows.forEach(row => table.push(row));
    if (deployRows.length) {
        const deploymentsSubtitle = [
            {
                hAlign: "left",
                colSpan: 2,
                content: chalk_1.default.green.bold("Deployments")
            },
            { hAlign: "right", colSpan: 3, content: "" },
            { hAlign: "left", colSpan: 1, content: chalk_1.default.bold(`% of limit`) }
        ];
        table.push(deploymentsSubtitle);
        deployRows.forEach((row) => table.push(row));
    }
    return table.toString();
}
exports.generateLegacyTextTable = generateLegacyTextTable;
//# sourceMappingURL=legacy.js.map