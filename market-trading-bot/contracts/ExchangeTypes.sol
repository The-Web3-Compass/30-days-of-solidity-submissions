// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ExchangeTypes {
    /// @dev User-defined type for exchange methods that can be approved. This
    /// matches the MsgType type defined in the Exchange authz types.
    type MsgType is uint8;

    /// @dev Define all the exchange methods available for approval.
    MsgType public constant MsgType_Deposit = MsgType.wrap(1);
    MsgType public constant MsgType_Withdraw = MsgType.wrap(2);
    MsgType public constant MsgType_SubaccountTransfer = MsgType.wrap(3);
    MsgType public constant MsgType_ExternalTransfer = MsgType.wrap(4);
    MsgType public constant MsgType_IncreasePositionMargin = MsgType.wrap(5);
    MsgType public constant MsgType_DecreasePositionMargin = MsgType.wrap(6);
    MsgType public constant MsgType_BatchUpdateOrders = MsgType.wrap(7);
    MsgType public constant MsgType_CreateDerivativeLimitOrder =
        MsgType.wrap(8);
    MsgType public constant MsgType_BatchCreateDerivativeLimitOrders =
        MsgType.wrap(9);
    MsgType public constant MsgType_CreateDerivativeMarketOrder =
        MsgType.wrap(10);
    MsgType public constant MsgType_CancelDerivativeOrder = MsgType.wrap(11);
    MsgType public constant MsgType_BatchCancelDerivativeOrders =
        MsgType.wrap(12);
    MsgType public constant MsgType_CreateSpotLimitOrder = MsgType.wrap(13);
    MsgType public constant MsgType_BatchCreateSpotLimitOrders =
        MsgType.wrap(14);
    MsgType public constant MsgType_CreateSpotMarketOrder = MsgType.wrap(15);
    MsgType public constant MsgType_CancelSpotOrder = MsgType.wrap(16);
    MsgType public constant MsgType_BatchCancelSpotOrders = MsgType.wrap(17);
    MsgType public constant MsgType_Unknown = MsgType.wrap(18);
}