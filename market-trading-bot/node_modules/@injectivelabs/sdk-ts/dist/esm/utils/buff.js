export const hexToBuff = (hex) => {
    return Buffer.from(hex.startsWith('0x') ? hex.slice(2) : hex, 'hex');
};
export const hexToBase64 = (hex) => {
    return Buffer.from(hex.startsWith('0x') ? hex.slice(2) : hex, 'hex').toString('base64');
};
