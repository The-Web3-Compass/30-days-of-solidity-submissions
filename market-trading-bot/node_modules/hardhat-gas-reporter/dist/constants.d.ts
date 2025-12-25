export declare const TABLE_NAME_LEGACY = "legacy";
export declare const TABLE_NAME_TERMINAL = "terminal";
export declare const TABLE_NAME_MARKDOWN = "markdown";
export declare const DEFAULT_CURRENCY = "USD";
export declare const DEFAULT_CURRENCY_DISPLAY_PRECISION = 2;
export declare const DEFAULT_JSON_OUTPUT_FILE = "./gasReporterOutput.json";
export declare const DEFAULT_GAS_PRICE_PRECISION = 5;
export declare const DEFAULT_BLOB_BASE_FEE_API_ARGS = "action=eth_call&data=0xf8206140&tag=latest&to=";
export declare const DEFAULT_GET_BLOCK_API_ARGS = "action=eth_getBlockByNumber&tag=latest&boolean=false";
export declare const DEFAULT_GAS_PRICE_API_ARGS = "action=eth_gasPrice";
export declare const DEFAULT_API_KEY_ARGS = "&apikey=";
export declare const DEFAULT_COINMARKET_BASE_URL = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/";
export declare const DEFAULT_OPTIMISM_HARDFORK = "ecotone";
export declare const DEFAULT_ARBITRUM_HARDFORK = "arbOS11";
export declare const TOOLCHAIN_HARDHAT = "hardhat";
export declare const TOOLCHAIN_FOUNDRY = "foundry";
export declare const CACHE_FILE_NAME = ".hardhat_gas_reporter_output.json";
export declare const EVM_BASE_TX_COST = 21000;
export declare const DEFAULT_BLOB_BASE_FEE = 10;
export declare const OPTIMISM_BEDROCK_FIXED_OVERHEAD = 188;
export declare const OPTIMISM_BEDROCK_DYNAMIC_OVERHEAD = 0.684;
export declare const OPTIMISM_ECOTONE_BASE_FEE_SCALAR = 1368;
export declare const OPTIMISM_ECOTONE_BLOB_BASE_FEE_SCALAR = 810949;
export declare const BASE_ECOTONE_BASE_FEE_SCALAR = 1101;
export declare const BASE_ECOTONE_BLOB_BASE_FEE_SCALAR = 659851;
export declare const UNICODE_CIRCLE = "\u25EF";
export declare const UNICODE_TRIANGLE = "\u25B3";
export declare const RANDOM_R_COMPONENT = "0x12354631f8e7f6d04a0f71b4e2a7b50b165ad2e50a83d531cbd88587b4bd62d5";
export declare const RANDOM_S_COMPONENT = "0x49cd68893c5952ea1e00288b05699be582081c5fba8c2c6f6e90dd416cdc2e07";
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
export declare const ARBITRUM_L1_ESTIMATE_CALLDATA = "0x77d488a2000000000000000000000000af88d065e77c8cc2239327c5edb3a432268e5831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004313ce56700000000000000000000000000000000000000000000000000000000";
export declare const ARBITRUM_NODE_INTERFACE_ADDRESS = "0x00000000000000000000000000000000000000C8";
export declare const DEFAULT_BASE_FEE_PER_BYTE_API_ARGS: string;
export declare const OPTIMISM_GAS_ORACLE_ABI_PARTIAL: {
    constant: boolean;
    inputs: any[];
    name: string;
    outputs: {
        name: string;
        type: string;
    }[];
    payable: boolean;
    stateMutability: string;
    type: string;
}[];
//# sourceMappingURL=constants.d.ts.map