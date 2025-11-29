"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChainGrpcInsuranceFundTransformer = void 0;
/**
 * @category Chain Grpc Transformer
 */
class ChainGrpcInsuranceFundTransformer {
    static moduleParamsResponseToModuleParams(response) {
        const params = response.params;
        return {
            defaultRedemptionNoticePeriodDuration: parseInt(params.defaultRedemptionNoticePeriodDuration?.seconds || '0', 10),
        };
    }
    static grpcInsuranceFundToInsuranceFund(grpcFund) {
        return {
            depositDenom: grpcFund.depositDenom,
            insurancePoolTokenDenom: grpcFund.insurancePoolTokenDenom,
            redemptionNoticePeriodDuration: parseInt(grpcFund.redemptionNoticePeriodDuration?.seconds || '0', 10),
            balance: grpcFund.balance,
            totalShare: grpcFund.totalShare,
            marketId: grpcFund.marketId,
            marketTicker: grpcFund.marketTicker,
            oracleBase: grpcFund.oracleBase,
            oracleQuote: grpcFund.oracleQuote,
            oracleType: grpcFund.oracleType,
            expiry: parseInt(grpcFund.expiry, 10),
        };
    }
    static insuranceFundResponseToInsuranceFund(response) {
        return ChainGrpcInsuranceFundTransformer.grpcInsuranceFundToInsuranceFund(response.fund);
    }
    static insuranceFundsResponseToInsuranceFunds(response) {
        return response.funds.map((fund) => ChainGrpcInsuranceFundTransformer.grpcInsuranceFundToInsuranceFund(fund));
    }
    static redemptionsResponseToRedemptions(response) {
        return response.amount.map((amount) => {
            return {
                amount: amount.amount,
                denom: amount.denom,
            };
        });
    }
    static estimatedRedemptionsResponseToEstimatedRedemptions(response) {
        return response.amount.map((amount) => {
            return {
                amount: amount.amount,
                denom: amount.denom,
            };
        });
    }
}
exports.ChainGrpcInsuranceFundTransformer = ChainGrpcInsuranceFundTransformer;
