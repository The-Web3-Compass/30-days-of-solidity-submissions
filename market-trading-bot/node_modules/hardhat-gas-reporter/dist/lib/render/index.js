"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.render = exports.getTableForFormat = void 0;
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
const constants_1 = require("../../constants");
const sources_1 = require("../../utils/sources");
const ui_1 = require("../../utils/ui");
const terminal_1 = require("./terminal");
const legacy_1 = require("./legacy");
const markdown_1 = require("./markdown");
const json_1 = require("./json");
/**
 * Table format selector
 * @param {HardhatRuntimeEnvironment} hre
 * @param {GasData}                   data
 * @param {GasReporterOptions}        options
 * @param {string}                    toolchain
 * @returns {string}                  table
 */
function getTableForFormat(hre, data, options, toolchain = "hardhat") {
    switch (options.reportFormat) {
        case constants_1.TABLE_NAME_LEGACY: return (0, legacy_1.generateLegacyTextTable)(hre, data, options);
        case constants_1.TABLE_NAME_TERMINAL: return (0, terminal_1.generateTerminalTextTable)(hre, data, options, toolchain);
        case constants_1.TABLE_NAME_MARKDOWN: return (0, markdown_1.generateMarkdownTable)(hre, data, options, toolchain);
        default:
            (0, ui_1.warnReportFormat)(options.reportFormat);
            return "";
    }
}
exports.getTableForFormat = getTableForFormat;
/**
 * Manages table rendering and file saving
 * @param {HardhatRuntimeEnvironment} hre
 * @param {GasReporterOptions}        options
 * @param {string[]}                  warnings
 * @param {string}                    toolchain
 */
function render(hre, options, warnings, toolchain = "hardhat") {
    const data = hre.__hhgrec.collector.data;
    options.blockGasLimit = hre.__hhgrec.blockGasLimit;
    options.solcInfo = (0, sources_1.getSolcInfo)(hre.config.solidity.compilers[0]);
    if (options.trackGasDeltas) {
        options.cachePath = options.cachePath || path_1.default.resolve(hre.config.paths.cache, constants_1.CACHE_FILE_NAME);
        try {
            const previousData = (0, json_1.loadJSONCache)(options);
            data.addDeltas(previousData.data);
        }
        catch { }
        ;
    }
    // Get table
    let table = getTableForFormat(hre, data, options, toolchain);
    // ---------------------------------------------------------------------------------------------
    // RST / ReadTheDocs / Sphinx output
    // ---------------------------------------------------------------------------------------------
    let rstOutput = "";
    if (options.rst) {
        rstOutput += `${options.rstTitle}\n`;
        rstOutput += `${"=".repeat(options.rstTitle.length)}\n\n`;
        rstOutput += `.. code-block:: shell\n\n`;
    }
    table = rstOutput + table;
    // ---------------------------------------------------------------------------------------------
    // Print
    // ---------------------------------------------------------------------------------------------
    if (options.outputFile) {
        (0, fs_1.writeFileSync)(options.outputFile, table);
        // Regenerate the table with full color if also logging to console
        if (options.forceTerminalOutput) {
            const originalOutputFile = options.outputFile;
            const originalNoColors = options.noColors;
            const originalReportFormat = options.reportFormat;
            options.outputFile = undefined;
            options.noColors = false;
            options.reportFormat = (options.forceTerminalOutputFormat)
                ? options.forceTerminalOutputFormat
                : options.reportFormat;
            table = getTableForFormat(hre, data, options);
            console.log(table);
            // Reset the options, since they might be read in JSON below here
            options.outputFile = originalOutputFile;
            options.noColors = originalNoColors;
            options.reportFormat = originalReportFormat;
        }
    }
    else if (!options.suppressTerminalOutput) {
        console.log(table);
    }
    if (options.outputJSON || process.env.CI) {
        (0, json_1.generateJSONData)(data, options, toolchain);
    }
    if (options.trackGasDeltas) {
        options.outputJSONFile = options.cachePath;
        (0, json_1.generateJSONData)(data, options, toolchain);
    }
    // Write warnings
    for (const warning of warnings)
        console.log(warning);
}
exports.render = render;
//# sourceMappingURL=index.js.map