/**
 * Returns a timeout timestamp in milliseconds so its compatible
 * with the way Cosmos handles transactions
 */
export declare const makeTimeoutTimestamp: (timeoutInMs?: number) => number;
/**
 * Returns a timeout timestamp in nanoseconds so its compatible
 * with the way Cosmos handles transactions
 */
export declare const makeTimeoutTimestampInNs: (timeoutInMs?: number) => number;
