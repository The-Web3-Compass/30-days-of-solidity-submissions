/**
 * @category Indexer Grpc Transformer
 */
export class IndexerGrpcInsuranceFundTransformer {
    static insuranceFundsResponseToInsuranceFunds(response) {
        const insuranceFunds = response.funds;
        return IndexerGrpcInsuranceFundTransformer.grpcInsuranceFundsToInsuranceFunds(insuranceFunds);
    }
    static redemptionsResponseToRedemptions(response) {
        const redemptions = response.redemptionSchedules;
        return IndexerGrpcInsuranceFundTransformer.grpcRedemptionsToRedemptions(redemptions);
    }
    static grpcInsuranceFundToInsuranceFund(grpcInsuranceFund) {
        const redemptionNoticePeriodDuration = grpcInsuranceFund.redemptionNoticePeriodDuration;
        const tokenMeta = grpcInsuranceFund.depositTokenMeta;
        const depositDenom = grpcInsuranceFund.depositDenom;
        return {
            depositDenom,
            insurancePoolTokenDenom: grpcInsuranceFund.poolTokenDenom,
            redemptionNoticePeriodDuration: parseInt(redemptionNoticePeriodDuration || '0', 10),
            balance: grpcInsuranceFund.balance,
            totalShare: grpcInsuranceFund.totalShare,
            depositTokenMeta: tokenMeta,
            marketId: grpcInsuranceFund.marketId,
            marketTicker: grpcInsuranceFund.marketTicker,
            oracleBase: grpcInsuranceFund.oracleBase,
            oracleQuote: grpcInsuranceFund.oracleQuote,
            oracleType: parseInt(grpcInsuranceFund.oracleType),
            expiry: parseInt(grpcInsuranceFund.expiry, 10),
        };
    }
    static grpcInsuranceFundsToInsuranceFunds(grpcInsuranceFunds) {
        return grpcInsuranceFunds.map(IndexerGrpcInsuranceFundTransformer.grpcInsuranceFundToInsuranceFund);
    }
    static grpcRedemptionToRedemption(redemption) {
        return {
            redemptionId: parseInt(redemption.redemptionId, 10),
            status: redemption.status,
            redeemer: redemption.redeemer,
            claimableRedemptionTime: parseInt(redemption.claimableRedemptionTime, 10),
            redemptionAmount: redemption.redemptionAmount,
            redemptionDenom: redemption.redemptionDenom,
            requestedAt: parseInt(redemption.requestedAt, 10),
            disbursedAmount: redemption.disbursedAmount,
            disbursedDenom: redemption.disbursedDenom,
            disbursedAt: parseInt(redemption.disbursedAt, 10),
        };
    }
    static grpcRedemptionsToRedemptions(redemptions) {
        return redemptions.map(IndexerGrpcInsuranceFundTransformer.grpcRedemptionToRedemption);
    }
}
