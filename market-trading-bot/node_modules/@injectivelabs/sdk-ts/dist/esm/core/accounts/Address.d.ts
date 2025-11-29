/**
 * @category Utility Classes
 */
export declare class Address {
    bech32Address: string;
    constructor(bech32Address: string);
    compare(address: Address): boolean;
    get address(): string;
    /**
     * Create an address instance from a bech32-encoded address and a prefix
     * @param {string} bech32 bech32-encoded address
     * @param {string} prefix
     * @return {Address}
     * @throws {Error} if bech is not a valid bech32-encoded address
     */
    static fromBech32(bech: string, prefix?: string): Address;
    /**
     * Create an address instance from an ethereum address
     * @param {string} hex Ethereum address
     * @param {string} prefix
     * @return {Address}
     * @throws {Error} if bech is not a valid bech32-encoded address
     */
    static fromHex(hex: string, prefix?: string): Address;
    /**
     * Convert an address instance to a bech32-encoded account address
     * @param {string} prefix
     * @returns {string}
     */
    toBech32(prefix?: string): string;
    /**
     * Return a bech32-encoded account address
     * @return {string}
     * @throws {Error} if this address is not a valid account address
     * */
    toAccountAddress(): string;
    /**
     * Return a bech32-encoded validator address
     * @return {string}
     * @throws {Error} if this address is not a valid validator address
     * */
    toValidatorAddress(): string;
    /**
     * Return a bech32-encoded consensus address
     * @return {string}
     * @throws {Error} if this address is not a valid consensus address
     * */
    toConsensusAddress(): string;
    /**
     * Return a hex representation of address
     * @return {string}
     * @throws {Error} if this address is not a valid account address
     * */
    toHex(): string;
    /**
     * Return a subaccount address from the given bech32 encoded address
     * @param {number} index the subaccount index
     * @return {string}
     * @throws {Error} if this address is not a valid account address
     * */
    getSubaccountId(index?: number): string;
    /**
     * Return a ethereum address from the given bech32 encoded address
     * @return {string}
     * @throws {Error} if this address is not a valid account address
     * */
    getEthereumAddress(): string;
}
