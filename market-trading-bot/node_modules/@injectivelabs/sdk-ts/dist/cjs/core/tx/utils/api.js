"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorToErrorMessage = exports.isTxNotFoundError = void 0;
const isTxNotFoundError = (error) => {
    if (!error.response) {
        const errorToString = error.toString();
        const acceptableErrorStrings = ['404', 'not found', 'timeout'];
        return acceptableErrorStrings.some((code) => errorToString.includes(code));
    }
    const message = error.response.data
        ? error.response.data.message
        : error.toString();
    if (message.includes('404')) {
        return true;
    }
    if (message.includes('not found')) {
        return true;
    }
    return false;
};
exports.isTxNotFoundError = isTxNotFoundError;
const errorToErrorMessage = (error) => {
    if (!error.response) {
        return error.toString();
    }
    const message = error.response.data
        ? error.response.data.message
        : error.toString();
    return message;
};
exports.errorToErrorMessage = errorToErrorMessage;
