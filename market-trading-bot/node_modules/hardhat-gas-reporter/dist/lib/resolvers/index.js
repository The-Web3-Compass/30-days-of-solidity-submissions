"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Resolver = void 0;
const oz_1 = require("./oz");
class Resolver {
    constructor(hre, options, data) {
        this.unresolvedCalls = 0;
        this.data = data;
        this.hre = hre;
        if (options.proxyResolver !== undefined) {
            this.resolveByProxy = options.proxyResolver.resolve.bind(this);
        }
        else if (hre.__hhgrec.usingOZ) {
            this.resolveByProxy = new oz_1.OZResolver().resolve.bind(this);
        }
        else {
            this.resolveByProxy = this.resolveByMethodSignature;
        }
    }
    /**
     * Searches all known contracts for the method signature and returns the first
     * found (if any). Undefined if none
     * @param  {Object} tx          result of web3.eth_getTransaction
     * @return {String}             contract name
     */
    resolveByMethodSignature(tx) {
        const signature = tx.input.slice(2, 10);
        const matches = this.data.getAllContractsWithMethod(signature);
        if (matches.length >= 1)
            return matches[0].contract;
        return null;
    }
    /**
     * Tries to match bytecode deployed at address to deployedBytecode listed
     * in artifacts. If found, adds this to the code-hash name mapping and
     * returns name.
     * @param  {String} address contract address
     * @return {String}         contract name
     */
    async resolveByDeployedBytecode(address) {
        if (!address)
            return null;
        const code = await this.hre.network.provider.send("eth_getCode", [address, "latest"]);
        const match = this.data.getContractByDeployedBytecode(code);
        if (match !== null) {
            await this.data.trackNameByAddress(match.name, address);
            return match.name;
        }
        return null;
    }
    /**
     * Helper for CustomResolvers which checks the existing contract address cache before
     * trying to resolve by deployed bytecode
     * @param contractAddress
     * @returns
     */
    async resolveViaCache(contractAddress) {
        if (contractAddress && contractAddress !== "0x") {
            const contractName = await this.data.getNameByAddress(contractAddress);
            if (contractName)
                return contractName;
            // Try to resolve by deployedBytecode
            return this.resolveByDeployedBytecode(contractAddress);
        }
    }
}
exports.Resolver = Resolver;
//# sourceMappingURL=index.js.map