import { Validator } from 'jsonschema';
import { Deployment, GasReporterOutput, MethodDataItem } from '../../types';
export declare class HardhatGasReporterOutputValidator {
    validator: Validator;
    constructor();
    validateOutputObject(output: GasReporterOutput, sourceFilePath: string): boolean;
    validateMethodDataItem(item: MethodDataItem, sourceFilePath: string): boolean;
    validateDeploymentDataItem(deployment: Deployment, sourceFilePath: string): boolean;
    private _checkResult;
}
//# sourceMappingURL=hardhat.d.ts.map