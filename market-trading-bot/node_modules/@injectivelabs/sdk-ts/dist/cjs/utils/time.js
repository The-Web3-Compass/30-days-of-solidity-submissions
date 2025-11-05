"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.makeTimeoutTimestampInNs = exports.makeTimeoutTimestamp = void 0;
const utils_1 = require("@injectivelabs/utils");
/**
 * Returns a timeout timestamp in milliseconds so its compatible
 * with the way Cosmos handles transactions
 */
const makeTimeoutTimestamp = (timeoutInMs = utils_1.DEFAULT_TIMESTAMP_TIMEOUT_MS) => {
    const now = new Date();
    const timestamp = new Date(now.getTime() + timeoutInMs);
    const actualTimestamp = timestamp.getTime();
    return actualTimestamp;
};
exports.makeTimeoutTimestamp = makeTimeoutTimestamp;
/**
 * Returns a timeout timestamp in nanoseconds so its compatible
 * with the way Cosmos handles transactions
 */
const makeTimeoutTimestampInNs = (timeoutInMs = utils_1.DEFAULT_TIMESTAMP_TIMEOUT_MS) => (0, exports.makeTimeoutTimestamp)(timeoutInMs) * 1e6;
exports.makeTimeoutTimestampInNs = makeTimeoutTimestampInNs;
