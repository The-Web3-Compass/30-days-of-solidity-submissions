/**
 * @category Chain Grpc Transformer
 */
export class ChainGrpcTokenFactoryTransformer {
    static moduleParamsResponseToModuleParams(response) {
        const params = response.params;
        return {
            denomCreationFee: params.denomCreationFee,
        };
    }
    static moduleStateResponseToModuleState(response) {
        const state = response.state;
        return {
            denomCreationFee: state.params.denomCreationFee,
            factoryDenoms: state.factoryDenoms.map((item) => ({
                denom: item.denom,
                authorityMetadata: item.authorityMetadata,
            })),
        };
    }
    static denomsCreatorResponseToDenomsString(response) {
        return response.denoms;
    }
    static authorityMetadataResponseToAuthorityMetadata(response) {
        return response.authorityMetadata;
    }
}
