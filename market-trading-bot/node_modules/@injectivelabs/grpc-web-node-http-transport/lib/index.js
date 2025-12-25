"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NodeHttpTransport = void 0;
var http = require("http");
var https = require("https");
var url = require("url");
var grpc_web_1 = require("@injectivelabs/grpc-web");
function NodeHttpTransport(httpsOptions) {
    return function (opts) {
        return new NodeHttp(opts, httpsOptions);
    };
}
exports.NodeHttpTransport = NodeHttpTransport;
var NodeHttp = (function () {
    function NodeHttp(transportOptions, httpsOptions) {
        this.httpsOptions = httpsOptions;
        this.options = transportOptions;
    }
    NodeHttp.prototype.sendMessage = function (msgBytes) {
        if (!this.options.methodDefinition.requestStream &&
            !this.options.methodDefinition.responseStream) {
            this.request.setHeader("Content-Length", msgBytes.byteLength);
        }
        this.request.write(toBuffer(msgBytes));
        this.request.end();
    };
    NodeHttp.prototype.finishSend = function () { };
    NodeHttp.prototype.responseCallback = function (response) {
        var _this = this;
        this.options.debug && console.log("NodeHttp.response", response.statusCode);
        var headers = filterHeadersForUndefined(response.headers);
        this.options.onHeaders(new grpc_web_1.grpc.Metadata(headers), response.statusCode);
        response.on("data", function (chunk) {
            _this.options.debug && console.log("NodeHttp.data", chunk);
            _this.options.onChunk(toArrayBuffer(chunk));
        });
        response.on("end", function () {
            _this.options.debug && console.log("NodeHttp.end");
            _this.options.onEnd();
        });
    };
    NodeHttp.prototype.start = function (metadata) {
        var _this = this;
        var headers = {};
        metadata.forEach(function (key, values) {
            headers[key] = values.join(", ");
        });
        var parsedUrl = url.parse(this.options.url);
        var httpOptions = {
            host: parsedUrl.hostname,
            port: parsedUrl.port ? parseInt(parsedUrl.port) : undefined,
            path: parsedUrl.path,
            headers: headers,
            method: "POST",
        };
        if (parsedUrl.protocol === "https:") {
            this.request = https.request(__assign(__assign({}, httpOptions), this === null || this === void 0 ? void 0 : this.httpsOptions), this.responseCallback.bind(this));
        }
        else {
            this.request = http.request(httpOptions, this.responseCallback.bind(this));
        }
        this.request.on("error", function (err) {
            _this.options.debug && console.log("NodeHttp.error", err);
            _this.options.onEnd(err);
        });
    };
    NodeHttp.prototype.cancel = function () {
        this.options.debug && console.log("NodeHttp.abort");
        this.request.abort();
    };
    return NodeHttp;
}());
function filterHeadersForUndefined(headers) {
    var filteredHeaders = {};
    for (var key in headers) {
        var value = headers[key];
        if (headers.hasOwnProperty(key)) {
            if (value !== undefined) {
                filteredHeaders[key] = value;
            }
        }
    }
    return filteredHeaders;
}
function toArrayBuffer(buf) {
    var view = new Uint8Array(buf.length);
    for (var i = 0; i < buf.length; i++) {
        view[i] = buf[i];
    }
    return view;
}
function toBuffer(ab) {
    var buf = Buffer.alloc(ab.byteLength);
    for (var i = 0; i < buf.length; i++) {
        buf[i] = ab[i];
    }
    return buf;
}
//# sourceMappingURL=index.js.map