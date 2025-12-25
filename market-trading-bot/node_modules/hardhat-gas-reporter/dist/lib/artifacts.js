"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getContracts = exports.getResolvedRemoteContracts = void 0;
const path_1 = __importDefault(require("path"));
const lodash_1 = __importDefault(require("lodash"));
const parser_1 = require("@solidity-parser/parser");
const abi_1 = require("@ethersproject/abi");
const sources_1 = require("../utils/sources");
/**
 * Filters out contracts to exclude from report
 * @param  {string}   qualifiedName        HRE artifact identifier
 * @param  {string[]} skippable            excludeContracts option values
 * @return {boolean}
 */
function shouldSkipContract(qualifiedName, skippable) {
    for (const item of skippable) {
        if (qualifiedName.includes(item)) {
            return true;
        }
    }
    return false;
}
/**
 * Fetches remote bytecode at address and hashes it so these addresses can be
 * added to the tracking in the collector
 * @param  {EGRAsyncApiProvider}   provider
 * @param  {RemoteContract[] = []} remoteContracts
 * @return {Promise<RemoteContract[]>}
 */
async function getResolvedRemoteContracts(provider, remoteContracts = []) {
    const { default: sha1 } = await Promise.resolve().then(() => __importStar(require("sha1")));
    for (const contract of remoteContracts) {
        try {
            contract.bytecode = await provider.send("eth_getCode", [contract.address, "latest"]);
            contract.deployedBytecode = contract.bytecode;
            contract.bytecodeHash = sha1(contract.bytecode);
        }
        catch (error) {
            console.log(`hardhat-gas-reporter:warning: failed to fetch bytecode for remote contract: ${contract.name}`);
            console.log(`Error was: ${error}\n`);
        }
    }
    return remoteContracts;
}
exports.getResolvedRemoteContracts = getResolvedRemoteContracts;
/**
 * Loads and processes artifacts
 * @param  {HardhatRuntimeEnvironment} hre
 * @param  {GasReporterOptions[]}      options
 * @return {ContractInfo[]}
 */
async function getContracts(hre, options) {
    const visited = {};
    const contracts = [];
    const resolvedRemoteContracts = await getResolvedRemoteContracts(hre.network.provider, options.remoteContracts);
    const resolvedQualifiedNames = await hre.artifacts.getAllFullyQualifiedNames();
    for (const qualifiedName of resolvedQualifiedNames) {
        if (shouldSkipContract(qualifiedName, options.excludeContracts)) {
            continue;
        }
        let name;
        let artifact = await hre.artifacts.readArtifact(qualifiedName);
        // Prefer simple names
        try {
            artifact = await hre.artifacts.readArtifact(artifact.contractName);
            name = artifact.contractName;
        }
        catch (e) {
            name = path_1.default.relative(hre.config.paths.sources, qualifiedName);
            ;
        }
        const excludedMethods = await getExcludedMethodKeys(hre, options, artifact.abi, name, qualifiedName, visited);
        contracts.push({
            name,
            excludedMethods,
            artifact: {
                abi: artifact.abi,
                bytecode: artifact.bytecode,
                deployedBytecode: artifact.deployedBytecode,
            },
        });
    }
    for (const remoteContract of resolvedRemoteContracts) {
        contracts.push({
            name: remoteContract.name,
            excludedMethods: [],
            artifact: {
                abi: remoteContract.abi,
                address: remoteContract.address,
                bytecode: remoteContract.bytecode,
                bytecodeHash: remoteContract.bytecodeHash,
                deployedBytecode: remoteContract.deployedBytecode,
            },
        });
    }
    return contracts;
}
exports.getContracts = getContracts;
/**
 * Parses each file in a contract's dependency tree to identify public StateVariables and
 * add them to a list of methods to exclude from the report. Enabled when
 * `excludeAutoGeneratedGetters` and `reportPureAndViewMethods` are both true.
 *
 * TODO: warn when files don't parse
 *
 * @param {HardhatRuntimeEnvironment} hre
 * @param {GasReporterOptions}        options
 * @param {any[]}                     abi
 * @param {string}                    name
 * @param {string}                    qualifiedName
 * @param {[key: string]: string[]}   visited (cache)
 * @returns {Promise<string[]>}
 */
async function getExcludedMethodKeys(hre, options, abi, contractName, contractQualifiedName, visited) {
    const excludedMethods = new Set();
    if (options.reportPureAndViewMethods && options.excludeAutoGeneratedGetters) {
        const info = await hre.artifacts.getBuildInfo(contractQualifiedName);
        const functions = new abi_1.Interface(abi).functions;
        if (info && info.input && info.input.sources) {
            lodash_1.default.forEach(info?.input.sources, (source, sourceKey) => {
                // Cache dependency sources
                if (!visited[sourceKey]) {
                    visited[sourceKey] = [];
                }
                else {
                    visited[sourceKey].forEach(_name => {
                        if (!excludedMethods.has(_name)) {
                            excludedMethods.add(`${contractName}_${(0, sources_1.getHashedFunctionSignature)(_name)}`);
                        }
                    });
                    return;
                }
                ;
                try {
                    const ast = (0, parser_1.parse)(source.content, { tolerant: true });
                    (0, parser_1.visit)(ast, {
                        StateVariableDeclaration(node) {
                            const publicVars = node.variables.filter(({ visibility }) => visibility === 'public');
                            publicVars.forEach(_var => {
                                const formattedName = Object.keys(functions).find(key => functions[key].name === _var.name);
                                if (formattedName) {
                                    visited[sourceKey].push(formattedName);
                                    excludedMethods.add(`${contractName}_${(0, sources_1.getHashedFunctionSignature)(formattedName)}`);
                                }
                            });
                        }
                    });
                }
                catch (err) { /* ignore */ }
            });
        }
    }
    return Array.from(excludedMethods);
}
//# sourceMappingURL=artifacts.js.map