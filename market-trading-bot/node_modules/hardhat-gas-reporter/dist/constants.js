"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OPTIMISM_GAS_ORACLE_ABI_PARTIAL = exports.DEFAULT_BASE_FEE_PER_BYTE_API_ARGS = exports.ARBITRUM_NODE_INTERFACE_ADDRESS = exports.ARBITRUM_L1_ESTIMATE_CALLDATA = exports.RANDOM_S_COMPONENT = exports.RANDOM_R_COMPONENT = exports.UNICODE_TRIANGLE = exports.UNICODE_CIRCLE = exports.BASE_ECOTONE_BLOB_BASE_FEE_SCALAR = exports.BASE_ECOTONE_BASE_FEE_SCALAR = exports.OPTIMISM_ECOTONE_BLOB_BASE_FEE_SCALAR = exports.OPTIMISM_ECOTONE_BASE_FEE_SCALAR = exports.OPTIMISM_BEDROCK_DYNAMIC_OVERHEAD = exports.OPTIMISM_BEDROCK_FIXED_OVERHEAD = exports.DEFAULT_BLOB_BASE_FEE = exports.EVM_BASE_TX_COST = exports.CACHE_FILE_NAME = exports.TOOLCHAIN_FOUNDRY = exports.TOOLCHAIN_HARDHAT = exports.DEFAULT_ARBITRUM_HARDFORK = exports.DEFAULT_OPTIMISM_HARDFORK = exports.DEFAULT_COINMARKET_BASE_URL = exports.DEFAULT_API_KEY_ARGS = exports.DEFAULT_GAS_PRICE_API_ARGS = exports.DEFAULT_GET_BLOCK_API_ARGS = exports.DEFAULT_BLOB_BASE_FEE_API_ARGS = exports.DEFAULT_GAS_PRICE_PRECISION = exports.DEFAULT_JSON_OUTPUT_FILE = exports.DEFAULT_CURRENCY_DISPLAY_PRECISION = exports.DEFAULT_CURRENCY = exports.TABLE_NAME_MARKDOWN = exports.TABLE_NAME_TERMINAL = exports.TABLE_NAME_LEGACY = void 0;
exports.TABLE_NAME_LEGACY = "legacy";
exports.TABLE_NAME_TERMINAL = "terminal";
exports.TABLE_NAME_MARKDOWN = "markdown";
exports.DEFAULT_CURRENCY = "USD";
exports.DEFAULT_CURRENCY_DISPLAY_PRECISION = 2;
exports.DEFAULT_JSON_OUTPUT_FILE = "./gasReporterOutput.json";
exports.DEFAULT_GAS_PRICE_PRECISION = 5;
// Selector generated with: ethersV5.Interface.encodeFunctionData("blobBaseFee()", []);
exports.DEFAULT_BLOB_BASE_FEE_API_ARGS = "action=eth_call&data=0xf8206140&tag=latest&to=";
exports.DEFAULT_GET_BLOCK_API_ARGS = "action=eth_getBlockByNumber&tag=latest&boolean=false";
exports.DEFAULT_GAS_PRICE_API_ARGS = "action=eth_gasPrice";
exports.DEFAULT_API_KEY_ARGS = "&apikey=";
exports.DEFAULT_COINMARKET_BASE_URL = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/";
exports.DEFAULT_OPTIMISM_HARDFORK = "ecotone";
exports.DEFAULT_ARBITRUM_HARDFORK = "arbOS11";
exports.TOOLCHAIN_HARDHAT = "hardhat";
exports.TOOLCHAIN_FOUNDRY = "foundry";
exports.CACHE_FILE_NAME = ".hardhat_gas_reporter_output.json";
// EVM
exports.EVM_BASE_TX_COST = 21000;
exports.DEFAULT_BLOB_BASE_FEE = 10; // gwei
// Source:
// https://docs.optimism.io/stack/transactions/fees#bedrock
exports.OPTIMISM_BEDROCK_FIXED_OVERHEAD = 188;
exports.OPTIMISM_BEDROCK_DYNAMIC_OVERHEAD = 0.684;
// These params are configured by node operators and may vary
// Values were read from the GasPriceOracle contract at:
// https://optimistic.etherscan.io/address/0x420000000000000000000000000000000000000F
exports.OPTIMISM_ECOTONE_BASE_FEE_SCALAR = 1368;
exports.OPTIMISM_ECOTONE_BLOB_BASE_FEE_SCALAR = 810949;
// https://basescan.org/address/0x420000000000000000000000000000000000000F
exports.BASE_ECOTONE_BASE_FEE_SCALAR = 1101;
exports.BASE_ECOTONE_BLOB_BASE_FEE_SCALAR = 659851;
exports.UNICODE_CIRCLE = "◯";
exports.UNICODE_TRIANGLE = "△";
exports.RANDOM_R_COMPONENT = "0x12354631f8e7f6d04a0f71b4e2a7b50b165ad2e50a83d531cbd88587b4bd62d5";
exports.RANDOM_S_COMPONENT = "0x49cd68893c5952ea1e00288b05699be582081c5fba8c2c6f6e90dd416cdc2e07";
/**
 * Generated with:
 *
 * erc20Calldata = ethersV5.Interface.encodeFunctionData("decimals()", [])
 *
 * ethersV5.Interface.encodeFunctionData(
 *   "gasEstimateL1Component(address to, bool contractCreation, bytes calldata data)",
 *   [
 *       "0xaf88d065e77c8cC2239327C5EDb3A432268e5831", // USDC
 *       false,
 *       erc20Calldata
 *   ]
 * );
 *
 */
exports.ARBITRUM_L1_ESTIMATE_CALLDATA = "0x77d488a2000000000000000000000000af88d065e77c8cc2239327c5edb3a432268e5831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004313ce56700000000000000000000000000000000000000000000000000000000";
// Source: @arbitrum/sdk/dist/lib/dataEntities/constants
exports.ARBITRUM_NODE_INTERFACE_ADDRESS = "0x00000000000000000000000000000000000000C8";
exports.DEFAULT_BASE_FEE_PER_BYTE_API_ARGS = `action=eth_call&data=${exports.ARBITRUM_L1_ESTIMATE_CALLDATA}&tag=latest&to=${exports.ARBITRUM_NODE_INTERFACE_ADDRESS}`;
exports.OPTIMISM_GAS_ORACLE_ABI_PARTIAL = [
    {
        constant: true,
        inputs: [],
        name: "blobBaseFee",
        outputs: [
            {
                name: "",
                type: "uint256",
            },
        ],
        payable: false,
        stateMutability: "view",
        type: "function",
    },
    {
        constant: true,
        inputs: [],
        name: "baseFeeScalar",
        outputs: [
            {
                name: "",
                type: "uint32",
            },
        ],
        payable: false,
        stateMutability: "view",
        type: "function",
    },
    {
        constant: true,
        inputs: [],
        name: "blobBaseFeeScalar",
        outputs: [
            {
                name: "",
                type: "uint32",
            },
        ],
        payable: false,
        stateMutability: "view",
        type: "function",
    }
];
//# sourceMappingURL=constants.js.map