"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChainGrpcTokenFactoryTransformer = void 0;
/**
 * @category Chain Grpc Transformer
 */
class ChainGrpcTokenFactoryTransformer {
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
exports.ChainGrpcTokenFactoryTransformer = ChainGrpcTokenFactoryTransformer;
