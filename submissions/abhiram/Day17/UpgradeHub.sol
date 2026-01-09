// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library SubscriptionStorage {
	bytes32 internal constant STORAGE_SLOT = keccak256("saas.subscription.manager.storage");

	struct Plan {
		string name;
		uint256 price;
		uint64 duration;
		bool active;
		bool exists;
	}

	struct UserSubscription {
		uint256 planId;
		uint64 expiresAt;
		bool paused;
		bool exists;
	}

	struct Data {
		uint256 nextPlanId;
		mapping(uint256 => Plan) plans;
		mapping(address => UserSubscription) subscriptions;
		address owner;
	}

	function data() internal pure returns (Data storage ds) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			ds.slot := slot
		}
	}
}

contract UpgradeHub {
	using SubscriptionStorage for SubscriptionStorage.Data;

	event PlanCreated(uint256 indexed planId, string name, uint256 price, uint64 duration, bool active);
	event PlanUpdated(uint256 indexed planId, string name, uint256 price, uint64 duration, bool active);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AccountSubscribed(address indexed account, uint256 indexed planId, uint64 expiresAt);
	event AccountRenewed(address indexed account, uint256 indexed planId, uint64 expiresAt);
	event AccountUpgraded(address indexed account, uint256 indexed oldPlanId, uint256 indexed newPlanId, uint64 expiresAt);
	event AccountPaused(address indexed account);
	event AccountResumed(address indexed account);
	event AccountCancelled(address indexed account, uint256 previousPlanId);

	modifier onlyOwner() {
		require(owner() == msg.sender, "not owner");
		_;
	}

	function initialize(address initialOwner) external {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		require(ds.owner == address(0), "initialized");
		require(initialOwner != address(0), "owner required");
		ds.owner = initialOwner;
		emit OwnershipTransferred(address(0), initialOwner);
	}

	function owner() public view returns (address) {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		return ds.owner;
	}

	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner != address(0), "owner required");
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		emit OwnershipTransferred(ds.owner, newOwner);
		ds.owner = newOwner;
	}

	function createPlan(
		string calldata name,
		uint256 price,
		uint64 duration,
		bool active
	) external onlyOwner returns (uint256 planId) {
		require(bytes(name).length != 0, "name required");
		require(duration > 0, "duration required");
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		planId = ds.nextPlanId;
		if (planId == 0) {
			planId = 1;
		}
		ds.nextPlanId = planId + 1;
		SubscriptionStorage.Plan storage plan = ds.plans[planId];
		plan.name = name;
		plan.price = price;
		plan.duration = duration;
		plan.active = active;
		plan.exists = true;
		emit PlanCreated(planId, name, price, duration, active);
	}

	function updatePlan(
		uint256 planId,
		string calldata name,
		uint256 price,
		uint64 duration,
		bool active
	) external onlyOwner {
		require(bytes(name).length != 0, "name required");
		require(duration > 0, "duration required");
		SubscriptionStorage.Plan storage plan = _getExistingPlan(planId);
		plan.name = name;
		plan.price = price;
		plan.duration = duration;
		plan.active = active;
		emit PlanUpdated(planId, name, price, duration, active);
	}

	function getPlan(uint256 planId)
		external
		view
		returns (string memory name, uint256 price, uint64 duration, bool active)
	{
		SubscriptionStorage.Plan storage plan = _getExistingPlan(planId);
		return (plan.name, plan.price, plan.duration, plan.active);
	}

	function getPlanCount() external view returns (uint256) {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		uint256 candidate = ds.nextPlanId;
		if (candidate == 0) {
			return 0;
		}
		return candidate - 1;
	}

	function subscribe(uint256 planId) external {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.Plan storage plan = _getExistingPlan(planId);
		require(plan.active, "inactive plan");
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[msg.sender];
		uint64 newExpiry = uint64(block.timestamp + plan.duration);
		if (sub.exists && sub.planId == planId && sub.expiresAt > block.timestamp) {
			newExpiry = uint64(sub.expiresAt + plan.duration);
		}
		sub.planId = planId;
		sub.expiresAt = newExpiry;
		sub.paused = false;
		sub.exists = true;
		emit AccountSubscribed(msg.sender, planId, newExpiry);
	}

	function renew(uint256 planId) external {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[msg.sender];
		require(sub.exists, "no subscription");
		require(sub.planId == planId, "plan mismatch");
		SubscriptionStorage.Plan storage plan = _getExistingPlan(planId);
		require(plan.active, "inactive plan");
		uint64 baseTime = sub.expiresAt > block.timestamp ? sub.expiresAt : uint64(block.timestamp);
		uint64 newExpiry = uint64(baseTime + plan.duration);
		sub.expiresAt = newExpiry;
		emit AccountRenewed(msg.sender, planId, newExpiry);
	}

	function upgrade(uint256 newPlanId) external {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[msg.sender];
		require(sub.exists, "no subscription");
		require(sub.planId != newPlanId, "already on plan");
		SubscriptionStorage.Plan storage plan = _getExistingPlan(newPlanId);
		require(plan.active, "inactive plan");
		uint256 oldPlanId = sub.planId;
		sub.planId = newPlanId;
		sub.expiresAt = uint64(block.timestamp + plan.duration);
		sub.paused = false;
		emit AccountUpgraded(msg.sender, oldPlanId, newPlanId, sub.expiresAt);
	}

	function pause(address account) external onlyOwner {
		SubscriptionStorage.UserSubscription storage sub = _getExistingSubscription(account);
		require(!sub.paused, "already paused");
		sub.paused = true;
		emit AccountPaused(account);
	}

	function resume(address account) external onlyOwner {
		SubscriptionStorage.UserSubscription storage sub = _getExistingSubscription(account);
		require(sub.paused, "not paused");
		sub.paused = false;
		emit AccountResumed(account);
	}

	function cancel(address account) external onlyOwner {
		_cancel(account, true);
	}

	function cancel() external {
		_cancel(msg.sender, false);
	}

	function getSubscription(address account)
		external
		view
		returns (uint256 planId, uint64 expiresAt, bool paused, bool active)
	{
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[account];
		if (!sub.exists) {
			return (0, 0, false, false);
		}
		SubscriptionStorage.Plan storage plan = ds.plans[sub.planId];
		bool isActive = plan.active && !sub.paused && sub.expiresAt >= block.timestamp;
		return (sub.planId, sub.expiresAt, sub.paused, isActive);
	}

	function isSubscriptionActive(address account) external view returns (bool) {
		(, , , bool active) = getSubscription(account);
		return active;
	}

	function version() external pure returns (string memory) {
		return "1.0.0";
	}

	function _cancel(address account, bool ownerDriven) private {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[account];
		require(sub.exists, "no subscription");
		if (ownerDriven) {
			require(owner() == msg.sender, "not owner");
		} else {
			require(account == msg.sender, "not subscriber");
		}
		uint256 previousPlanId = sub.planId;
		delete ds.subscriptions[account];
		emit AccountCancelled(account, previousPlanId);
	}

	function _getExistingPlan(uint256 planId) private view returns (SubscriptionStorage.Plan storage) {
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.Plan storage plan = ds.plans[planId];
		require(plan.exists, "plan missing");
		return plan;
	}

	function _getExistingSubscription(address account)
		private
		view
		returns (SubscriptionStorage.UserSubscription storage)
	{
		SubscriptionStorage.Data storage ds = SubscriptionStorage.data();
		SubscriptionStorage.UserSubscription storage sub = ds.subscriptions[account];
		require(sub.exists, "no subscription");
		return sub;
	}
}

contract SubscriptionProxy {
	// Slots follow EIP-1967 convention to avoid clashing with logic storage.
	bytes32 private constant IMPLEMENTATION_SLOT =
		bytes32(uint256(keccak256("subscription.proxy.implementation")) - 1);
	bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("subscription.proxy.admin")) - 1);

	event Upgraded(address indexed newImplementation);
	event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

	modifier onlyAdmin() {
		require(msg.sender == _getAdmin(), "not admin");
		_;
	}

	constructor(address initialImplementation, bytes memory initData) {
		require(initialImplementation != address(0), "implementation required");
		_setAdmin(msg.sender);
		_upgradeTo(initialImplementation, initData);
	}

	function upgradeTo(address newImplementation, bytes calldata initData) external onlyAdmin {
		_upgradeTo(newImplementation, initData);
	}

	function implementation() external view returns (address) {
		return _getImplementation();
	}

	function admin() external view returns (address) {
		return _getAdmin();
	}

	function changeAdmin(address newAdmin) external onlyAdmin {
		require(newAdmin != address(0), "admin required");
		address previous = _getAdmin();
		_setAdmin(newAdmin);
		emit AdminChanged(previous, newAdmin);
	}

	fallback() external payable {
		_delegate();
	}

	receive() external payable {
		_delegate();
	}

	function _upgradeTo(address newImplementation, bytes memory initData) private {
		_requireContract(newImplementation);
		_setImplementation(newImplementation);
		emit Upgraded(newImplementation);
		if (initData.length != 0) {
			(bool success, bytes memory returndata) = newImplementation.delegatecall(initData);
			if (!success) {
				assembly {
					revert(add(returndata, 32), mload(returndata))
				}
			}
		}
	}

	function _delegate() private {
		address impl = _getImplementation();
		require(impl != address(0), "implementation missing");
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}

	function _getImplementation() private view returns (address impl) {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			impl := sload(slot)
		}
	}

	function _setImplementation(address newImplementation) private {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			sstore(slot, newImplementation)
		}
	}

	function _getAdmin() private view returns (address adm) {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			adm := sload(slot)
		}
	}

	function _setAdmin(address newAdmin) private {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			sstore(slot, newAdmin)
		}
	}

	function _requireContract(address target) private view {
		uint256 size;
		assembly {
			size := extcodesize(target)
		}
		require(size > 0, "not a contract");
	}
}