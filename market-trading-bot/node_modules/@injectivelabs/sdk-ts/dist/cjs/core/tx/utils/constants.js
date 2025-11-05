"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SIGN_EIP712_V2 = exports.SIGN_EIP712 = exports.SIGN_AMINO = exports.SIGN_DIRECT = void 0;
const core_proto_ts_1 = require("@injectivelabs/core-proto-ts");
exports.SIGN_DIRECT = core_proto_ts_1.CosmosTxSigningV1Beta1Signing.SignMode.SIGN_MODE_DIRECT;
exports.SIGN_AMINO = core_proto_ts_1.CosmosTxSigningV1Beta1Signing.SignMode.SIGN_MODE_LEGACY_AMINO_JSON;
exports.SIGN_EIP712 = core_proto_ts_1.CosmosTxSigningV1Beta1Signing.SignMode.SIGN_MODE_LEGACY_AMINO_JSON;
exports.SIGN_EIP712_V2 = core_proto_ts_1.CosmosTxSigningV1Beta1Signing.SignMode.SIGN_MODE_EIP712_V2;
