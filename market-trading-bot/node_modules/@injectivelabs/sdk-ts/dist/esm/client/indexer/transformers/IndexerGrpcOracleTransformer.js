export class IndexerGrpcOracleTransformer {
    static oraclesResponseToOracles(response) {
        const oracles = response.oracles;
        return oracles.map((o) => IndexerGrpcOracleTransformer.grpcOracleToOracle(o));
    }
    static grpcOracleToOracle(grpcOracle) {
        return grpcOracle;
    }
}
