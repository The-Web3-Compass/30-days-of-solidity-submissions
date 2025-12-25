"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IndexerAuctionStreamTransformer = void 0;
const ts_types_1 = require("@injectivelabs/ts-types");
/**
 * @category Indexer Stream Transformer
 */
class IndexerAuctionStreamTransformer {
    static bidsStreamCallback = (response) => ({
        bid: {
            bidder: response.bidder,
            bidAmount: response.bidAmount,
            bidTimestamp: parseInt(response.timestamp, 10),
        },
        operation: ts_types_1.StreamOperation.Insert,
    });
}
exports.IndexerAuctionStreamTransformer = IndexerAuctionStreamTransformer;
