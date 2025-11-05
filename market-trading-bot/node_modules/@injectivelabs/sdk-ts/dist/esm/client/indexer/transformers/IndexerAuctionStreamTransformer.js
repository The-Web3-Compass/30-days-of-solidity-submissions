import { StreamOperation } from '@injectivelabs/ts-types';
/**
 * @category Indexer Stream Transformer
 */
export class IndexerAuctionStreamTransformer {
    static bidsStreamCallback = (response) => ({
        bid: {
            bidder: response.bidder,
            bidAmount: response.bidAmount,
            bidTimestamp: parseInt(response.timestamp, 10),
        },
        operation: StreamOperation.Insert,
    });
}
