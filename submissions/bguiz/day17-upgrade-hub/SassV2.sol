// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { SaasStorage } from "./SaasStorage.sol";

/**
 * @title SaasV2
 **/
contract SaasV2 is SaasStorage {
    function addPlan(
        uint256 price,
        uint256 duration,
        bool pausable,
        uint8 discountForAnnual
    ) public returns(uint8 planId) {
        require(duration >= 1_000_000, "less than minimun duration");
        require(price > 0, "zero price plan not allowed");
        require(discountForAnnual >=0 && discountForAnnual < 100, "annual discount must be a percentage value");
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
        uint256 duration
    ) public {
        require(plans[planId].price > 0, "no such plan");
        Sub memory sub = Sub({
            planId: planId,
            expiry: block.timestamp + duration,
            paused: false
        });
        subs[msg.sender] = sub;
    }
}
