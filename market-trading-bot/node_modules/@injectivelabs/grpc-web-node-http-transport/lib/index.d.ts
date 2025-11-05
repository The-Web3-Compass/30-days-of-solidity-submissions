/// <reference types="node" />
import * as https from "https";
import { grpc } from "@injectivelabs/grpc-web";
export declare function NodeHttpTransport(httpsOptions?: https.RequestOptions): grpc.TransportFactory;
