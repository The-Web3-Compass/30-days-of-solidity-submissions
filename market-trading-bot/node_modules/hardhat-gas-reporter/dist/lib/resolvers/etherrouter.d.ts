import { CustomGasReporterResolver, JsonRpcTx } from "../../types";
import { Resolver } from "./index";
/**
 * Example of a class that resolves the contract names of method calls routed through
 * a simple proxy (EtherRouter-style) contract. At runtime, the function below will be bound to
 * the `this` property of plugin's Resolver class and inherit its resources which include:
 *
 * > helpers to match methods to contracts (e.g all public methods on the Resolver & GasData classes)
 * > the HardhatRuntimeEnvironment (so you can access all env extensions and the network provider.)
 *
 * The method receives a JSONRPC formatted transaction object representing a tx
 * the reporter could not deterministically associate with any contract. It relies on your
 * knowledge of a proxy contract's API to derive the correct contract name.
 *
 * Returns contract name matching the resolved address.
 * @param  {Object} transaction JSONRPC formatted transaction
 * @return {String}             contract name
 */
export declare class EtherRouterResolver implements CustomGasReporterResolver {
    /**
     * Because the gas reporter tracks `eth_calls` made with the provider, the class
     * needs to declare the function signatures it uses to retrieve the identity of proxied
     * targets on-chain. If these aren't filtered by the GasReporterProvider it gets
     * trapped in an infinite loop.
     */
    ignore(): string[];
    resolve(this: Resolver, transaction: JsonRpcTx): Promise<string | null>;
}
//# sourceMappingURL=etherrouter.d.ts.map