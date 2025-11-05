"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.hexToBase64 = exports.hexToBuff = void 0;
const hexToBuff = (hex) => {
    return Buffer.from(hex.startsWith('0x') ? hex.slice(2) : hex, 'hex');
};
exports.hexToBuff = hexToBuff;
const hexToBase64 = (hex) => {
    return Buffer.from(hex.startsWith('0x') ? hex.slice(2) : hex, 'hex').toString('base64');
};
exports.hexToBase64 = hexToBase64;
