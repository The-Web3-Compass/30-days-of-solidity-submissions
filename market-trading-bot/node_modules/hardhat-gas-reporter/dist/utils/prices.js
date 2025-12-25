"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setGasAndPriceRates = void 0;
const axios_1 = __importDefault(require("axios"));
const abi_1 = require("@ethersproject/abi");
const constants_1 = require("../constants");
const ui_1 = require("./ui");
const gas_1 = require("./gas");
const chains_1 = require("./chains");
/**
 * Fetches gas, base, & blob fee rates from etherscan as well as current market value of
 * network token in nation state currency specified by the options from coinmarketcap
 * (defaults to usd). Sets
 *
 * + options.tokenPrice
 * + options.gasPrice
 * + options.baseFee
 * + options.blobBaseFee
 *
 * ... unless these are already set as constants in the reporter options
 *
 * Returns a list of warnings generated if remote calls fail
 * @param  {GasReporterOptions} options
 */
async function setGasAndPriceRates(options) {
    if ((options.offline) ||
        !options.coinmarketcap ||
        (!options.L2 && options.tokenPrice && options.gasPrice) ||
        (options.L2 && options.tokenPrice && options.gasPrice && options.baseFee && options.blobBaseFee))
        return [];
    let block;
    let blockUrl;
    let gasPriceUrl;
    let blobBaseFeeUrl;
    let baseFeePerByteUrl;
    const warnings = [];
    try {
        options.token = (0, chains_1.getTokenForChain)(options);
        gasPriceUrl = (0, chains_1.getGasPriceUrlForChain)(options);
        blockUrl = (0, chains_1.getBlockUrlForChain)(options);
        blobBaseFeeUrl = (0, chains_1.getBlobBaseFeeUrlForChain)(options);
        baseFeePerByteUrl = (0, chains_1.getBaseFeePerByteUrlForChain)(options);
    }
    catch (err) {
        if (options.L2)
            warnings.push((0, ui_1.warnUnsupportedChainConfig)(options.L2));
        else
            warnings.push((0, ui_1.warnUnsupportedChainConfig)(options.L1));
        return warnings;
    }
    const axiosInstance = axios_1.default.create({
        baseURL: constants_1.DEFAULT_COINMARKET_BASE_URL
    });
    const requestArgs = `latest?symbol=${options.token}&CMC_PRO_API_KEY=${options.coinmarketcap}&convert=`;
    const currencyKey = options.currency.toUpperCase();
    const currencyPath = `${requestArgs}${currencyKey}`;
    // Currency market data: coinmarketcap
    if (!options.tokenPrice) {
        try {
            const response = await axiosInstance.get(currencyPath);
            options.tokenPrice = response.data.data[options.token].quote[currencyKey].price.toFixed(2);
        }
        catch (error) {
            warnings.push((0, ui_1.warnCMCRemoteCallFailed)(error, constants_1.DEFAULT_COINMARKET_BASE_URL + currencyPath));
        }
    }
    // Gas price data (Etherscan)
    if (!options.gasPrice) {
        try {
            const response = await axiosInstance.get(gasPriceUrl);
            checkForEtherscanError(response.data.result);
            const gasPrice = (0, gas_1.hexWeiToIntGwei)(response.data.result);
            options.gasPrice = (gasPrice >= 1) ? Math.round(gasPrice) : gasPrice;
            ;
        }
        catch (error) {
            options.gasPrice = 0;
            warnings.push((0, ui_1.warnGasPriceRemoteCallFailed)(error, gasPriceUrl));
        }
    }
    // baseFeePerByte data: etherscan eth_call to NodeInterface
    if ((options.L2 === "arbitrum") && !options.baseFeePerByte) {
        try {
            const response = await axiosInstance.get(baseFeePerByteUrl);
            checkForEtherscanError(response.data.result);
            const decoded = abi_1.defaultAbiCoder.decode(['uint256', 'uint256', 'uint256'], response.data.result);
            const baseFeePerByte = (0, gas_1.getArbitrumBaseFeePerByte)(decoded[2]);
            options.baseFeePerByte = (baseFeePerByte >= 1) ? Math.round(baseFeePerByte) : baseFeePerByte;
        }
        catch (error) {
            options.baseFeePerByte = 20;
            warnings.push((0, ui_1.warnBaseFeePerByteRemoteCallFailed)(error));
        }
    }
    // baseFee data (Etherscan)
    if ((options.L2 === "optimism" || options.L2 === "base") && !options.baseFee) {
        try {
            block = await axiosInstance.get(blockUrl);
            checkForEtherscanError(block.data.result);
            const baseFee = (0, gas_1.hexWeiToIntGwei)(block.data.result.baseFeePerGas);
            options.baseFee = (baseFee >= 1) ? Math.round(baseFee) : baseFee;
        }
        catch (error) {
            options.baseFee = 0;
            warnings.push((0, ui_1.warnBaseFeeRemoteCallFailed)(error, blockUrl));
        }
    }
    // blobBaseFee data: etherscan eth_call to OP Stack gas oracle on L2
    if ((options.L2 === "optimism" || options.L2 === "base") &&
        options.optimismHardfork === "ecotone" &&
        !options.blobBaseFee) {
        try {
            const response = await axiosInstance.get(blobBaseFeeUrl);
            checkForEtherscanError(response.data.result);
            const blobBaseFee = (0, gas_1.hexWeiToIntGwei)(response.data.result);
            options.blobBaseFee = (blobBaseFee >= 1) ? Math.round(blobBaseFee) : blobBaseFee;
        }
        catch (error) {
            options.blobBaseFee = constants_1.DEFAULT_BLOB_BASE_FEE;
            warnings.push((0, ui_1.warnBlobBaseFeeRemoteCallFailed)(error));
        }
    }
    return warnings;
}
exports.setGasAndPriceRates = setGasAndPriceRates;
function checkForEtherscanError(res) {
    if (typeof res === "string" && !res.includes("0x")) {
        throw new Error(res);
    }
}
//# sourceMappingURL=prices.js.map