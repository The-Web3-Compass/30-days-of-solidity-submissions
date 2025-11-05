import { SolcConfig } from "hardhat/types";
import { SolcInfo } from "../types";
/**
 * Generates hashed function selector from the human readable function signature
 * @param {string} fnSig
 * @returns
 */
export declare function getHashedFunctionSignature(fnSig: string): string;
/**
 * Generates id for a GasData.methods entry from the input of a web3.eth.getTransaction
 * and a contract name
 * @param  {String} contractName
 * @param  {String} code             hex data
 * @return {String}                  id
 */
export declare function getMethodID(contractName: string, code: string): string;
/**
 * Extracts solc settings and version info from solidity metadata
 * @param  {Object} solcConfig solidity config
 * @return {Object}          {version, optimizer, runs}
 */
export declare function getSolcInfo(solcConfig: SolcConfig): SolcInfo;
/**
 * Return true if transaction input and bytecode are same, ignoring library link code.
 * @param  {String} input       contract creation tx `input`
 * @param  {String} bytecode    contract bytecode
 * @return {Bool}
 */
export declare function matchBinaries(input: string, bytecode: string): boolean;
/**
 * Generate a regular expression string which is library link agnostic so we can match
 * linked bytecode deployment transaction inputs to the evm.bytecode solc output.
 * @param  {String} bytecode
 * @return {String}
 */
export declare function bytecodeToBytecodeRegex(bytecode?: string): string;
//# sourceMappingURL=sources.d.ts.map