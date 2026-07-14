export type ExecDataRepresentation<Data> = {
    origin: string;
    name: string;
    args: Data;
};
export type ExecDataRepresentationWithInjectiveExec<Data> = {
    injective_exec: {
        origin: string;
        name: string;
        args: Data;
    };
};
export declare const dataToExecData: <T>(data: T, execParams: {
    origin: string;
    name: string;
}) => ExecDataRepresentation<T>;
export declare const dataToExecDataWithInjectiveExec: <T>(data: T, execParams: {
    origin: string;
    name: string;
}) => ExecDataRepresentationWithInjectiveExec<T>;
/** Executing Messages with injective_exec */
export declare abstract class ExecPrivilegedArgBase<Params, DataRepresentation> {
    params: Params;
    constructor(params: Params);
    abstract toData(): DataRepresentation;
    abstract toExecData(): ExecDataRepresentation<DataRepresentation>;
    toJSON(): string;
    toExecJSON(): string;
}
export declare abstract class MsgExecPrivilegedArgBase<Params, DataRepresentation> {
    params: Params;
    constructor(params: Params);
    abstract toData(): DataRepresentation;
    toJSON(): string;
}
