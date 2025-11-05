"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IndexerAccountPortfolioStreamTransformer = void 0;
/**
 * @category Indexer Stream Transformer
 */
class IndexerAccountPortfolioStreamTransformer {
    static accountPortfolioStreamCallback = (response) => {
        return {
            type: response.type,
            denom: response.denom,
            amount: response.amount,
            subaccountId: response.subaccountId,
        };
    };
}
exports.IndexerAccountPortfolioStreamTransformer = IndexerAccountPortfolioStreamTransformer;
