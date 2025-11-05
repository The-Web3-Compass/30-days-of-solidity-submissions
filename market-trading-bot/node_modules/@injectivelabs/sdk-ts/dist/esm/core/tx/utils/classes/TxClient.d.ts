import { CosmosTxV1Beta1Tx } from '@injectivelabs/core-proto-ts';
export declare class TxClient {
    /**
     * Encode a transaction to base64-encoded protobuf
     * @param tx transaction to encode
     */
    static encode(tx: CosmosTxV1Beta1Tx.TxRaw): string;
    /**
     * Decode a transaction from base64-encoded protobuf
     * @param tx transaction string to decode
     */
    static decode(encodedTx: string): CosmosTxV1Beta1Tx.TxRaw;
    /**
     * Get the transaction's hash
     * @param tx transaction to hash
     */
    static hash(tx: CosmosTxV1Beta1Tx.TxRaw): string;
}
