export function fromUtf8(str) {
    if (typeof str !== 'string') {
        return str;
    }
    return new TextEncoder().encode(str);
}
export function toUtf8(data) {
    if (typeof data === 'string') {
        return data;
    }
    return new TextDecoder('utf-8', { fatal: true }).decode(data);
}
export function binaryToBase64(data) {
    return typeof data === 'string' ? data : Buffer.from(data).toString('base64');
}
export function toBase64(data) {
    return Buffer.from(JSON.stringify(data)).toString('base64');
}
export function fromBase64(payload) {
    return JSON.parse(Buffer.from(payload, 'base64').toString());
}
