"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IndexerGrpcOracleTransformer = void 0;
class IndexerGrpcOracleTransformer {
    static oraclesResponseToOracles(response) {
        const oracles = response.oracles;
        return oracles.map((o) => IndexerGrpcOracleTransformer.grpcOracleToOracle(o));
    }
    static grpcOracleToOracle(grpcOracle) {
        return grpcOracle;
    }
}
exports.IndexerGrpcOracleTransformer = IndexerGrpcOracleTransformer;
