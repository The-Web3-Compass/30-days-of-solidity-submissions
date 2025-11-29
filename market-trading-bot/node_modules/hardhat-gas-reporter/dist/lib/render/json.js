"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadJSONCache = exports.generateJSONData = void 0;
const fs_1 = require("fs");
/**
 * Writes accumulated data and the current options to gasReporterOutput.json so it
 * can be consumed by other tools (CI etc...)
 * @param {GasData}               data
 * @param {GasReporterOptions}    options
 * @param {string}                toolchain
 */
function generateJSONData(data, options, toolchain = "hardhat") {
    const pkg = require("../../../package.json");
    _sanitizeGasData(data, options);
    const output = {
        namespace: "HardhatGasReporter",
        toolchain,
        version: pkg.version,
        options,
        data
    };
    (0, fs_1.writeFileSync)(options.outputJSONFile, JSON.stringify(output, null, ' '));
}
exports.generateJSONData = generateJSONData;
/**
 * Reads previous acccumulated data and options from cache so it can be used to calculate deltas
 * @param {GasReporterOptions} options
 * @returns {GasReporterOptions} previous data and options
 */
function loadJSONCache(options) {
    return JSON.parse((0, fs_1.readFileSync)(options.cachePath).toString());
}
exports.loadJSONCache = loadJSONCache;
/**
 * Removes extraneous data and attached methods
 * @param {GasData} data
 * @param {GasReporterOptions} options
 */
function _sanitizeGasData(data, options) {
    delete options.proxyResolver;
    delete data.addressCache;
    delete data.codeHashMap;
    delete data.provider;
    if (!options.includeBytecodeInJSON) {
        data.deployments.forEach(deployment => {
            delete deployment.bytecode;
            delete deployment.deployedBytecode;
        });
    }
    if (options.coinmarketcap) {
        options.coinmarketcap = "[REDACTED]";
    }
    if (options.etherscan) {
        options.etherscan = "[REDACTED]";
    }
    // Options deprecated in 2.3.0
    if (options.L1Etherscan) {
        options.L1Etherscan = "[REDACTED]";
    }
    if (options.L2Etherscan) {
        options.L2Etherscan = "[REDACTED]";
    }
}
//# sourceMappingURL=json.js.map