export type ExecDataRepresentation<Data> = {
    [key: string]: Data;
};
export declare const dataToExecData: <T>(action: string, data: T) => ExecDataRepresentation<T>;
export declare abstract class ExecArgBase<Params, DataRepresentation> {
    params: Params;
    constructor(params: Params);
    abstract toData(): DataRepresentation;
    abstract toExecData(): ExecDataRepresentation<DataRepresentation>;
    toJSON(): Uint8Array;
    toExecJSON(): Uint8Array;
}
