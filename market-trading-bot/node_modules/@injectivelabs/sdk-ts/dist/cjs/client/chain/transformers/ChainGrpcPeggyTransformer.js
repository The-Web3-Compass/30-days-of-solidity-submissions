"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChainGrpcPeggyTransformer = void 0;
/**
 * @category Chain Grpc Transformer
 */
class ChainGrpcPeggyTransformer {
    static moduleParamsResponseToModuleParams(response) {
        const params = response.params;
        const valsetReward = params.valsetReward;
        return {
            peggyId: params.peggyId,
            contractSourceHash: params.contractSourceHash,
            bridgeEthereumAddress: params.bridgeEthereumAddress,
            bridgeChainId: params.bridgeChainId,
            signedValsetsWindow: params.signedValsetsWindow,
            signedBatchesWindow: params.signedBatchesWindow,
            signedClaimsWindow: params.signedClaimsWindow,
            targetBatchTimeout: params.targetBatchTimeout,
            averageBlockTime: params.averageBlockTime,
            averageEthereumBlockTime: params.averageEthereumBlockTime,
            slashFractionValset: params.slashFractionValset,
            slashFractionBatch: params.slashFractionBatch,
            slashFractionClaim: params.slashFractionClaim,
            slashFractionConflictingClaim: params.slashFractionConflictingClaim,
            unbondSlashingValsetsWindow: params.unbondSlashingValsetsWindow,
            slashFractionBadEthSignature: params.slashFractionBadEthSignature,
            cosmosCoinDenom: params.cosmosCoinDenom,
            cosmosCoinErc20Contract: params.cosmosCoinErc20Contract,
            claimSlashingEnabled: params.claimSlashingEnabled,
            bridgeContractStartHeight: params.bridgeContractStartHeight,
            valsetReward: {
                denom: valsetReward.denom,
                amount: valsetReward.amount,
            },
        };
    }
}
exports.ChainGrpcPeggyTransformer = ChainGrpcPeggyTransformer;
