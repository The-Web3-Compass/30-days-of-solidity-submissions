// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { SaasStorage } from "./SaasStorage.sol";

/**
 * @title SaasV1
 **/
contract SaasV1 is SaasStorage {
    function addPlan(
        uint256 price,
        uint256 duration,
        bool pausable,
        uint8 discountForAnnual
    ) public returns(uint8 planId) {
        planId = ++planCount;
        Plan memory plan = Plan({
            price: price,
            duration: duration,
            pausable: pausable,
            discountForAnnual: discountForAnnual
        });
        plans[planId] = plan;
    }

    function addSubscription(
        uint8 planId,
        uint256 expiryDuration
    ) public {
        Sub memory sub = Sub({
            planId: planId,
            expiry: block.timestamp + expiryDuration,
            paused: false
        });
        subs[msg.sender] = sub;
    }
}
