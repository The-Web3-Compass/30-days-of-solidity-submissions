import { GasReporterOptions, GasReporterExecutionContext } from "./types";
declare module "hardhat/types/config" {
    interface HardhatConfig {
        gasReporter: Partial<GasReporterOptions>;
    }
}
declare module "hardhat/types/config" {
    interface HardhatUserConfig {
        gasReporter?: Partial<GasReporterOptions>;
    }
}
declare module "hardhat/types/runtime" {
    interface HardhatRuntimeEnvironment {
        __hhgrec: GasReporterExecutionContext;
    }
}
//# sourceMappingURL=type-extensions.d.ts.map