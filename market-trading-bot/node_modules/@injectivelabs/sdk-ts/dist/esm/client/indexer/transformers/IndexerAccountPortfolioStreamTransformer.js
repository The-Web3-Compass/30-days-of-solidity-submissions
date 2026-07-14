/**
 * @category Indexer Stream Transformer
 */
export class IndexerAccountPortfolioStreamTransformer {
    static accountPortfolioStreamCallback = (response) => {
        return {
            type: response.type,
            denom: response.denom,
            amount: response.amount,
            subaccountId: response.subaccountId,
        };
    };
}
