"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.bytecodeToBytecodeRegex = exports.matchBinaries = exports.getSolcInfo = exports.getMethodID = exports.getHashedFunctionSignature = void 0;
const keccak_1 = require("ethereum-cryptography/keccak");
const utils_1 = require("ethereum-cryptography/utils");
/**
 * Generates hashed function selector from the human readable function signature
 * @param {string} fnSig
 * @returns
 */
function getHashedFunctionSignature(fnSig) {
    return (0, utils_1.bytesToHex)((0, keccak_1.keccak256)(Buffer.from((0, utils_1.utf8ToBytes)(fnSig)))).slice(0, 8);
}
exports.getHashedFunctionSignature = getHashedFunctionSignature;
/**
 * Generates id for a GasData.methods entry from the input of a web3.eth.getTransaction
 * and a contract name
 * @param  {String} contractName
 * @param  {String} code             hex data
 * @return {String}                  id
 */
function getMethodID(contractName, code) {
    return `${contractName}_${code.slice(2, 10)}`;
}
exports.getMethodID = getMethodID;
/**
 * Extracts solc settings and version info from solidity metadata
 * @param  {Object} solcConfig solidity config
 * @return {Object}          {version, optimizer, runs}
 */
function getSolcInfo(solcConfig) {
    const info = {};
    const optimizer = solcConfig.settings.optimizer;
    const viaIR = solcConfig.settings.viaIR;
    if (solcConfig) {
        info.version = solcConfig.version;
        info.optimizer = (optimizer) ? optimizer.enabled : "----";
        info.runs = (optimizer) ? optimizer.runs : "----";
        info.viaIR = (viaIR !== undefined) ? viaIR : false;
    }
    return info;
}
exports.getSolcInfo = getSolcInfo;
/**
 * Return true if transaction input and bytecode are same, ignoring library link code.
 * @param  {String} input       contract creation tx `input`
 * @param  {String} bytecode    contract bytecode
 * @return {Bool}
 */
function matchBinaries(input, bytecode) {
    const regExp = bytecodeToBytecodeRegex(bytecode);
    return input.match(regExp) !== null;
}
exports.matchBinaries = matchBinaries;
/**
 * Generate a regular expression string which is library link agnostic so we can match
 * linked bytecode deployment transaction inputs to the evm.bytecode solc output.
 * @param  {String} bytecode
 * @return {String}
 */
function bytecodeToBytecodeRegex(bytecode = "") {
    const bytecodeRegex = bytecode
        .replace(/__.{38}/g, ".{40}")
        .replace(/73f{40}/g, ".{42}");
    // HACK: Node regexes can't be longer that 32767 characters.
    // Contracts bytecode can. We just truncate the regexes. It's safe in practice.
    const MAX_REGEX_LENGTH = 32767;
    const truncatedBytecodeRegex = bytecodeRegex.slice(0, MAX_REGEX_LENGTH);
    return truncatedBytecodeRegex;
}
exports.bytecodeToBytecodeRegex = bytecodeToBytecodeRegex;
//# sourceMappingURL=sources.js.map