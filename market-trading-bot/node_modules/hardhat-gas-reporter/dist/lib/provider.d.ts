import { ProviderWrapper } from "hardhat/plugins";
import { EIP1193Provider, RequestArguments } from "hardhat/types";
import { GasReporterExecutionContext } from "../types";
/**
 * Wrapped provider which collects tx data
 */
export declare class GasReporterProvider extends ProviderWrapper {
    isInitialized: boolean;
    private _executionContext;
    constructor(provider: EIP1193Provider);
    /**
     * extendProvider doesn't expose the environment but that's where we store data
     * and context stuff while bookending the start & finish of other tasks
     * @param {GasReporterExecutionContext} context
     */
    initializeGasReporterProvider(context: GasReporterExecutionContext): void;
    /**
     * Handles calls for TruffleV5
     * @param {RequestArguments} args
     * @returns {Promise<any>}
     */
    private _handleTruffleV5;
    /**
     * Handles calls for Ethers (`eth_getTransactionReceipt`). (Ethers calls this when tx is mined)
     * @param {RequestArguments} args
     * @returns {Promise<any>}
     */
    private _handleEthers;
    /**
     * Handles calls for Waffle (`eth_sendRawTransaction`) and Viem (`eth_sendTransaction`)
     * @param {RequestArguments} args
     * @returns {Promise<any>}
     */
    private _handleViemOrWaffle;
    /**
     * Handles `eth_call` (for pure and view fns)
     * @param {RequestArguments} args
     * @returns {Promise<any>}
     */
    private _handleEthCall;
    /**
     * Dispatch table for all the call routes required for different providers and call types
     * @param {RequestArguments} args
     * @returns {Promise<any>}
     */
    request(args: RequestArguments): Promise<unknown>;
    /**
     * Used by `eth_call` to check that we're tracking calls and that the call being made is
     * not disallowed by a Resolver. Resolvers need to make private calls to establish proxied
     * contract identities - if we don't filter them here we get stuck in an infinite loop.
     * @param args
     * @returns
     */
    private _canEstimate;
}
//# sourceMappingURL=provider.d.ts.map