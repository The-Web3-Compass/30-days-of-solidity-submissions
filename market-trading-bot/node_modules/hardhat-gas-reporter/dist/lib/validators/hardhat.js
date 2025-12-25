"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HardhatGasReporterOutputValidator = void 0;
const jsonschema_1 = require("jsonschema");
const plugins_1 = require("hardhat/plugins");
const os_1 = require("os");
const ReporterOutputSchema = {
    id: "hardhat.hhgr.output.json",
    type: "object",
    properties: {
        namespace: { type: "string" },
        toolchain: { type: "string" },
        version: { type: "string" },
        options: { type: "object" },
        data: {
            type: "object",
            properties: {
                "methods": { type: "object" },
                "deployments": { type: "array", "items": { "type": "object" } }
            },
            required: ["methods", "deployments"]
        }
    },
    required: ["toolchain", "data", "options"]
};
const MethodDataSchema = {
    id: "hardhat.hhgr.methods.json",
    type: "object",
    properties: {
        callData: { type: "array", "items": { "type": "number" }, "required": true },
        gasData: { type: "array", "items": { "type": "number" }, "required": true },
        numberOfCalls: { type: "number", "required": true },
    }
};
const DeploymentDataSchema = {
    id: "hardhat.hhgr.deployments.json",
    type: "object",
    properties: {
        name: { type: "string", "required": true },
        callData: { type: "array", "items": { "type": "number" }, "required": true },
        gasData: { type: "array", "items": { "type": "number" }, "required": true },
    }
};
class HardhatGasReporterOutputValidator {
    constructor() {
        this.validator = new jsonschema_1.Validator();
        this.validator.addSchema(ReporterOutputSchema);
        this.validator.addSchema(MethodDataSchema);
        this.validator.addSchema(DeploymentDataSchema);
    }
    validateOutputObject(output, sourceFilePath) {
        const result = this.validator.validate(output, ReporterOutputSchema);
        this._checkResult(result, sourceFilePath);
        return true;
    }
    validateMethodDataItem(item, sourceFilePath) {
        const result = this.validator.validate(item, MethodDataSchema);
        this._checkResult(result, sourceFilePath);
        return true;
    }
    validateDeploymentDataItem(deployment, sourceFilePath) {
        const result = this.validator.validate(deployment, DeploymentDataSchema);
        this._checkResult(result, sourceFilePath);
        return true;
    }
    _checkResult(result, sourceFilePath) {
        if (result.errors.length) {
            let errors = "";
            for (const err of result.errors) {
                errors += err.stack.replace("instance.", "") + os_1.EOL;
            }
            ;
            throw new plugins_1.HardhatPluginError("hardhat-gas-reporter", `Unexpected JSON report format in ${sourceFilePath}. ` +
                `Reported JSON validation error was: ${os_1.EOL}${errors}`);
        }
    }
}
exports.HardhatGasReporterOutputValidator = HardhatGasReporterOutputValidator;
//# sourceMappingURL=hardhat.js.map