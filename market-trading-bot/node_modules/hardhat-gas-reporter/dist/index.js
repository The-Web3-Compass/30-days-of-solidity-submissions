"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.initializeGasReporterProvider = void 0;
const lodash_1 = require("lodash"); // used in extendConfig, cannot await import
const task_names_1 = require("hardhat/builtin-tasks/task-names");
const config_1 = require("hardhat/config");
require("./type-extensions");
const options_1 = require("./lib/options");
const provider_1 = require("./lib/provider");
const task_names_2 = require("./task-names");
let _globalGasReporterProviderReference;
// ========================
// EXTENSIONS
// ========================
/* Config */
(0, config_1.extendConfig)((config, userConfig) => {
    let options = (0, options_1.getDefaultOptions)(userConfig);
    // Deep clone userConfig otherwise HH will throw unauthorized modification error
    if (userConfig.gasReporter !== undefined) {
        options = Object.assign(options, (0, lodash_1.cloneDeep)(userConfig.gasReporter));
        // Use legacy Etherscan API Key if user did not migrate from deprecated options
        if (options.L1Etherscan && !options.etherscan) {
            options.etherscan = options.L1Etherscan;
        }
    }
    config.gasReporter = options;
});
/* Environment */
(0, config_1.extendEnvironment)((hre) => {
    hre.__hhgrec = {
        collector: undefined,
        task: undefined,
    };
});
/* Provider */
(0, config_1.extendProvider)(async (provider) => {
    const newProvider = new provider_1.GasReporterProvider(provider);
    _globalGasReporterProviderReference = newProvider;
    return newProvider;
});
/*
   Initialize the provider with the execution context. This is called in
   `TASK_GAS_REPORTER_START` at the very end of setup. Provider extension above should
   not be used on unrelated tasks.
*/
async function initializeGasReporterProvider(provider, context) {
    // Other plugins (ex: hardhat-tracer) may wrap the provider in a way
    // that doesn't expose `init()`, so we init the underlying provider
    // here by making a cheap call.
    await provider.request({ method: "eth_blockNumber", params: [] });
    _globalGasReporterProviderReference.initializeGasReporterProvider(context);
}
exports.initializeGasReporterProvider = initializeGasReporterProvider;
// ========================
// BUILT-IN OVERRIDES
// ========================
/**
 * Overrides Hardhat built-in task TASK_TEST to report gas usage
 */
(0, config_1.task)(task_names_1.TASK_TEST).setAction(async (args, hre, runSuper) => {
    hre.__hhgrec.task = task_names_1.TASK_TEST;
    await hre.run(task_names_2.TASK_GAS_REPORTER_START, args);
    await runSuper(args);
    await hre.run(task_names_2.TASK_GAS_REPORTER_STOP, args);
});
// ========================
// GAS REPORTER TASKS
// ========================
/**
 * Initializes gas tracking
 */
(0, config_1.subtask)(task_names_2.TASK_GAS_REPORTER_START).setAction(async (args, hre) => {
    const options = hre.config.gasReporter;
    if (options.enabled === true) {
        // Lazy load all imports to minimize HH startup time
        const { getContracts } = await Promise.resolve().then(() => __importStar(require("./lib/artifacts")));
        const { Collector } = await Promise.resolve().then(() => __importStar(require("./lib/collector")));
        const { warnParallel } = await Promise.resolve().then(() => __importStar(require("./utils/ui")));
        // Temporarily skipping when in parallel mode because it crashes and
        // unsure how to resolve...
        if (args.parallel === true) {
            warnParallel();
            return;
        }
        // solidity-coverage disables gas reporter via mocha but that
        // no longer works for this version. (No warning necessary)
        if (hre.__SOLIDITY_COVERAGE_RUNNING === true) {
            return;
        }
        // Need to compile so we have access to the artifact data.
        // This will rerun in TASK_TEST & TASK_RUN but should be a noop there.
        if (!args.noCompile) {
            await hre.run(task_names_1.TASK_COMPILE, { quiet: true });
        }
        const contracts = await getContracts(hre, options);
        hre.__hhgrec.usingCall = options.reportPureAndViewMethods;
        hre.__hhgrec.usingViem = hre.viem;
        hre.__hhgrec.usingOZ = hre.upgrades || hre.defender;
        hre.__hhgrec.collector = new Collector(hre, options);
        hre.__hhgrec.collector.data.initialize(hre.network.provider, contracts);
        // Custom proxy resolvers are instantiated in the config,
        // OZ proxy resolver instantiated in Resolver constructor called by new Collector()
        hre.__hhgrec.methodIgnoreList = (options.proxyResolver)
            ? options.proxyResolver.ignore()
            : [];
        await initializeGasReporterProvider(hre.network.provider, hre.__hhgrec);
    }
});
/**
 * Completes gas reporting: gets live market data, runs analysis and renders
 */
(0, config_1.subtask)(task_names_2.TASK_GAS_REPORTER_STOP).setAction(async (args, hre) => {
    const options = hre.config.gasReporter;
    if (options.enabled === true &&
        args.parallel !== true &&
        hre.__SOLIDITY_COVERAGE_RUNNING !== true) {
        const { setGasAndPriceRates } = await Promise.resolve().then(() => __importStar(require("./utils/prices")));
        const { render } = await Promise.resolve().then(() => __importStar(require("./lib/render")));
        const warnings = await setGasAndPriceRates(options);
        await hre.__hhgrec.collector?.data.runAnalysis(hre, options);
        render(hre, options, warnings);
    }
});
/**
 * ========================
 * CLI COMMAND TASKS
 * ========================
 */
(0, config_1.subtask)(task_names_2.TASK_GAS_REPORTER_MERGE_REPORTS)
    .addOptionalVariadicPositionalParam("inputFiles", "Path of several gasReporterOutput.json files to merge", [])
    .setAction(async ({ inputFiles }) => {
    const { subtaskMergeReportsImplementation } = await Promise.resolve().then(() => __importStar(require("./tasks/mergeReports")));
    return subtaskMergeReportsImplementation({ inputFiles });
});
(0, config_1.task)(task_names_2.TASK_GAS_REPORTER_MERGE)
    .addOptionalParam("output", "Target file to save the merged report", "gasReporterOutput.json")
    .addVariadicPositionalParam("input", "A list of JSON data files generated by the gas reporter plugin. " +
    "Files can be defined using glob patterns")
    .setAction(async (taskArguments, hre) => {
    const { taskMergeImplementation } = await Promise.resolve().then(() => __importStar(require("./tasks/mergeReports")));
    return taskMergeImplementation(taskArguments, hre);
});
/**
 * ========================
 * DEPRECATED TASKS
 * ========================
 */
(0, config_1.task)(task_names_2.TASK_GAS_REPORTER_MERGE_LEGACY)
    .addOptionalParam("output", "Target file to save the merged report", "gasReporterOutput.json")
    .addVariadicPositionalParam("input")
    .setAction(async () => {
    const { warnDeprecatedTask } = await Promise.resolve().then(() => __importStar(require("./utils/ui")));
    warnDeprecatedTask(task_names_2.TASK_GAS_REPORTER_MERGE);
});
(0, config_1.subtask)(task_names_2.TASK_GAS_REPORTER_MERGE_REPORTS_LEGACY)
    .addOptionalVariadicPositionalParam("inputFiles", "", [])
    .setAction(async ({}) => {
    const { warnDeprecatedTask } = await Promise.resolve().then(() => __importStar(require("./utils/ui")));
    warnDeprecatedTask(task_names_2.TASK_GAS_REPORTER_MERGE_REPORTS);
});
//# sourceMappingURL=index.js.map