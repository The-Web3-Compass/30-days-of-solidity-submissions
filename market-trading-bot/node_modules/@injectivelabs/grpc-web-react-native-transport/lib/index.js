"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReactNativeTransport = void 0;
var grpc_web_1 = require("@injectivelabs/grpc-web");
function ReactNativeTransport(init) {
    return function (opts) {
        return new ArrayBufferXHR(opts, init);
    };
}
exports.ReactNativeTransport = ReactNativeTransport;
var awaitingExecution = null;
function runCallbacks() {
    if (awaitingExecution) {
        var thisCallbackSet = awaitingExecution;
        awaitingExecution = null;
        for (var i = 0; i < thisCallbackSet.length; i++) {
            try {
                thisCallbackSet[i]();
            }
            catch (e) {
                if (awaitingExecution === null) {
                    awaitingExecution = [];
                    setTimeout(function () {
                        runCallbacks();
                    }, 0);
                }
                for (var k = thisCallbackSet.length - 1; k > i; k--) {
                    awaitingExecution.unshift(thisCallbackSet[k]);
                }
                throw e;
            }
        }
    }
}
function debug() {
    var args = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        args[_i] = arguments[_i];
    }
    if (console.debug) {
        console.debug.apply(null, args);
    }
    else {
        console.log.apply(null, args);
    }
}
function detach(cb) {
    if (awaitingExecution !== null) {
        awaitingExecution.push(cb);
        return;
    }
    awaitingExecution = [cb];
    setTimeout(function () {
        runCallbacks();
    }, 0);
}
function stringToArrayBuffer(str) {
    var asArray = new Uint8Array(str.length);
    var arrayIndex = 0;
    for (var i = 0; i < str.length; i++) {
        var codePoint = String.prototype.codePointAt
            ? str.codePointAt(i)
            : codePointAtPolyfill(str, i);
        asArray[arrayIndex++] = codePoint & 0xff;
    }
    return asArray;
}
function codePointAtPolyfill(str, index) {
    var code = str.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
        var surr = str.charCodeAt(index + 1);
        if (surr >= 0xdc00 && surr <= 0xdfff) {
            code = 0x10000 + ((code - 0xd800) << 10) + (surr - 0xdc00);
        }
    }
    return code;
}
var XHR = (function () {
    function XHR(transportOptions, init) {
        this.options = transportOptions;
        this.init = init;
    }
    XHR.prototype.onProgressEvent = function () {
        var _this = this;
        this.options.debug &&
            debug("XHR.onProgressEvent.length: ", this.xhr.response.length);
        var rawText = this.xhr.response.substr(this.index);
        this.index = this.xhr.response.length;
        var asArrayBuffer = stringToArrayBuffer(rawText);
        detach(function () {
            _this.options.onChunk(asArrayBuffer);
        });
    };
    XHR.prototype.onLoadEvent = function () {
        var _this = this;
        detach(function () {
            _this.options.onEnd();
        });
    };
    XHR.prototype.onStateChange = function () {
        var _this = this;
        if (this.xhr.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
            detach(function () {
                _this.options.onHeaders(new grpc_web_1.grpc.Metadata(_this.xhr.getAllResponseHeaders()), _this.xhr.status);
            });
        }
    };
    XHR.prototype.sendMessage = function (msgBytes) {
        this.xhr.send(msgBytes);
    };
    XHR.prototype.finishSend = function () { };
    XHR.prototype.start = function (metadata) {
        var _this = this;
        this.metadata = metadata;
        var xhr = new XMLHttpRequest();
        this.xhr = xhr;
        xhr.open("POST", this.options.url);
        this.configureXhr();
        this.metadata.forEach(function (key, values) {
            xhr.setRequestHeader(key, values.join(", "));
        });
        xhr.withCredentials = Boolean(this.init.withCredentials);
        xhr.addEventListener("readystatechange", this.onStateChange.bind(this));
        xhr.addEventListener("progress", this.onProgressEvent.bind(this));
        xhr.addEventListener("loadend", this.onLoadEvent.bind(this));
        xhr.addEventListener("error", function (err) {
            detach(function () {
                _this.options.onEnd(err.error);
            });
        });
    };
    XHR.prototype.configureXhr = function () {
        this.xhr.responseType = "text";
        this.xhr.overrideMimeType("text/plain; charset=x-user-defined");
    };
    XHR.prototype.cancel = function () {
        this.xhr.abort();
    };
    return XHR;
}());
var ArrayBufferXHR = (function (_super) {
    __extends(ArrayBufferXHR, _super);
    function ArrayBufferXHR() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ArrayBufferXHR.prototype.configureXhr = function () {
        this.options.debug &&
            debug("ArrayBufferXHR.configureXhr: setting responseType to 'arraybuffer'");
        this.xhr.responseType = "arraybuffer";
    };
    ArrayBufferXHR.prototype.onProgressEvent = function () { };
    ArrayBufferXHR.prototype.onLoadEvent = function () {
        var _this = this;
        var resp = this.xhr.response;
        this.options.debug &&
            debug("ArrayBufferXHR.onLoadEvent: ", new Uint8Array(resp));
        detach(function () {
            _this.options.onChunk(new Uint8Array(resp), true);
        });
        detach(function () {
            _this.options.onEnd();
        });
    };
    return ArrayBufferXHR;
}(XHR));
//# sourceMappingURL=index.js.map