/**
 * @title DecentralizedEscrow
 * @dev 去中心化托管
 * 功能点：重点是安全、有条件的交易
 * 1. 托管服务：安全存储资金
 * 2. 有条件付款：基于预设条件释放资金
 * 3. 争议解决：处理买卖双方的争议
 * 4. 管理付款：控制资金流向
 * 5. 数字中间人：确保交易安全
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DecentralizedEscrow is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // 托管交易状态
    enum EscrowState {
        Created,    // 已创建
        Funded,     // 已支付
        Completed,  // 已完成
        Refunded,   // 已退款
        Disputed,   // 争议中
        Resolved    // 已解决
    }

    // 争议解决方式
    enum DisputeResolution {
        None,           // 无
        RefundBuyer,    // 退款给买家
        PaySeller,      // 支付给卖家
        Split          // 分割支付
    }

    // 托管交易结构体
    struct Escrow {
        address payable buyer;      // 买家地址
        address payable seller;     // 卖家地址
        address token;              // 代币地址（address(0)表示ETH）
        uint256 amount;             // 金额
        uint256 deadline;           // 截止时间
        string terms;               // 交易条款
        EscrowState state;          // 交易状态
        bool buyerApproved;         // 买家确认
        bool sellerApproved;        // 卖家确认
        uint256 disputeTime;        // 争议提出时间
        string disputeReason;       // 争议原因
        DisputeResolution resolution; // 争议解决方式
    }

    // 状态变量
    uint256 public escrowCount;                     // 托管交易总数
    mapping(uint256 => Escrow) public escrows;      // 托管交易映射
    uint256 public constant DISPUTE_TIMEOUT = 7 days; // 争议处理超时时间
    uint256 public constant PLATFORM_FEE = 1;        // 平台费率（1%）
    uint256 public constant SPLIT_RATIO = 50;        // 分割比例（50%）

    // 事件
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId);
    event EscrowRefunded(uint256 indexed escrowId);
    event DisputeRaised(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed escrowId, DisputeResolution resolution);
    event ApprovalSubmitted(uint256 indexed escrowId, address indexed party, bool approved);

    constructor() Ownable(msg.sender) {
    }

    /**
     * @dev 创建托管交易 
     
     */
    function createEscrow(
        address payable seller,
        address token,
        uint256 amount,
        uint256 duration,
        string calldata terms
    ) external returns (uint256) {
        require(seller != address(0), "Invalid seller address");
        require(amount > 0, "Amount must be greater than 0");
        require(bytes(terms).length > 0, "Terms cannot be empty");

        uint256 escrowId = escrowCount++;
        uint256 deadline = block.timestamp + duration;

        escrows[escrowId] = Escrow({
            buyer: payable(msg.sender),
            seller: seller,
            token: token,
            amount: amount,
            deadline: deadline,
            terms: terms,
            state: EscrowState.Created,
            buyerApproved: false,
            sellerApproved: false,
            disputeTime: 0,
            disputeReason: "",
            resolution: DisputeResolution.None
        });

        emit EscrowCreated(escrowId, msg.sender, seller, amount);
        return escrowId;
    }

    /**
     * @dev 支付托管资金
     */
    function fundEscrow(uint256 escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.buyer == msg.sender, "Only buyer can fund");
        require(escrow.state == EscrowState.Created, "Invalid state for funding");
        require(block.timestamp < escrow.deadline, "Escrow expired");

        uint256 totalAmount = escrow.amount + (escrow.amount * PLATFORM_FEE) / 100;

        if (escrow.token == address(0)) {
            // ETH支付
            require(msg.value == totalAmount, "Incorrect ETH amount");
        } else {
            // ERC20代币支付
            require(msg.value == 0, "ETH not accepted for token escrow");
            IERC20(escrow.token).safeTransferFrom(msg.sender, address(this), totalAmount);
        }

        escrow.state = EscrowState.Funded;
        emit EscrowFunded(escrowId, totalAmount);
    }

    /**
     * @dev 提交确认
     */
    function submitApproval(uint256 escrowId, bool approved) external {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Invalid state for approval");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not a party to escrow");

        if (msg.sender == escrow.buyer) {
            escrow.buyerApproved = approved;
        } else {
            escrow.sellerApproved = approved;
        }

        emit ApprovalSubmitted(escrowId, msg.sender, approved);

        // 如果双方都同意，完成交易
        if (escrow.buyerApproved && escrow.sellerApproved) {
            _completeEscrow(escrowId);
        }
    }

    /**
     * @dev 完成托管交易
     */
    function _completeEscrow(uint256 escrowId) internal {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Invalid state for completion");

        escrow.state = EscrowState.Completed;

        // 计算平台费用和卖家收款金额
        uint256 platformFee = (escrow.amount * PLATFORM_FEE) / 100;
        uint256 sellerAmount = escrow.amount;

        // 转账
        if (escrow.token == address(0)) {
            // ETH转账
            (bool success1, ) = escrow.seller.call{value: sellerAmount}("");
            require(success1, "ETH transfer to seller failed");
            
            // 转移平台费用给合约所有者
            (bool success2, ) = owner().call{value: platformFee}("");
            require(success2, "ETH platform fee transfer failed");
        } else {
            // ERC20代币转账
            IERC20(escrow.token).safeTransfer(escrow.seller, sellerAmount);
            // 转移平台费用给合约所有者
            IERC20(escrow.token).safeTransfer(owner(), platformFee);
        }

        emit EscrowCompleted(escrowId);
    }

    /**
     * @dev 提出争议
     */
    function raiseDispute(uint256 escrowId, string calldata reason) external {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not a party to escrow");
        require(escrow.state == EscrowState.Funded, "Invalid state for dispute");
        require(bytes(reason).length > 0, "Reason cannot be empty");

        escrow.state = EscrowState.Disputed;
        escrow.disputeTime = block.timestamp;
        escrow.disputeReason = reason;

        emit DisputeRaised(escrowId, msg.sender, reason);
    }

    /**
     * @dev 解决争议（仅管理员）
     */
    function resolveDispute(uint256 escrowId, DisputeResolution resolution) external onlyOwner {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Not in dispute");
        require(resolution != DisputeResolution.None, "Invalid resolution");

        escrow.state = EscrowState.Resolved;
        escrow.resolution = resolution;

        uint256 buyerAmount;
        uint256 sellerAmount;
        uint256 platformFee = (escrow.amount * PLATFORM_FEE) / 100;

        // 根据解决方案分配资金
        if (resolution == DisputeResolution.RefundBuyer) {
            buyerAmount = escrow.amount;
            sellerAmount = 0;
        } else if (resolution == DisputeResolution.PaySeller) {
            buyerAmount = 0;
            sellerAmount = escrow.amount;
        } else if (resolution == DisputeResolution.Split) {
            buyerAmount = (escrow.amount * SPLIT_RATIO) / 100;
            sellerAmount = escrow.amount - buyerAmount;
        }

        // 转账
        if (escrow.token == address(0)) {
            // ETH转账
            if (buyerAmount > 0) {
                (bool success1, ) = escrow.buyer.call{value: buyerAmount}("");
                require(success1, "Buyer ETH transfer failed");
            }
            if (sellerAmount > 0) {
                (bool success2, ) = escrow.seller.call{value: sellerAmount}("");
                require(success2, "Seller ETH transfer failed");
            }
            // 转移平台费用给合约所有者
            (bool success3, ) = owner().call{value: platformFee}("");
            require(success3, "ETH platform fee transfer failed");
        } else {
            // ERC20代币转账
            if (buyerAmount > 0) {
                IERC20(escrow.token).safeTransfer(escrow.buyer, buyerAmount);
            }
            if (sellerAmount > 0) {
                IERC20(escrow.token).safeTransfer(escrow.seller, sellerAmount);
            }
            // 转移平台费用给合约所有者
            IERC20(escrow.token).safeTransfer(owner(), platformFee);
        }

        emit DisputeResolved(escrowId, resolution);
    }

    /**
     * @dev 超时自动退款
     */
    function refundExpired(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Invalid state for refund");
        require(block.timestamp >= escrow.deadline, "Escrow not expired");

        escrow.state = EscrowState.Refunded;

        // 退还资金（包括平台费用）
        uint256 totalAmount = escrow.amount + (escrow.amount * PLATFORM_FEE) / 100;

        if (escrow.token == address(0)) {
            // ETH退款
            (bool success, ) = escrow.buyer.call{value: totalAmount}("");
            require(success, "ETH refund failed");
        } else {
            // ERC20代币退款
            IERC20(escrow.token).safeTransfer(escrow.buyer, totalAmount);
        }

        emit EscrowRefunded(escrowId);
    }

    /**
     * @dev 获取托管交易详情
     */
    function getEscrow(uint256 escrowId) external view returns (
        address buyer,
        address seller,
        address token,
        uint256 amount,
        uint256 deadline,
        string memory terms,
        EscrowState state,
        bool buyerApproved,
        bool sellerApproved,
        uint256 disputeTime,
        string memory disputeReason,
        DisputeResolution resolution
    ) {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.buyer,
            escrow.seller,
            escrow.token,
            escrow.amount,
            escrow.deadline,
            escrow.terms,
            escrow.state,
            escrow.buyerApproved,
            escrow.sellerApproved,
            escrow.disputeTime,
            escrow.disputeReason,
            escrow.resolution
        );
    }

    /**
     * @dev 提取平台费用（仅管理员）
     */
    function withdrawPlatformFees(address token) external onlyOwner {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
            require(balance > 0, "No ETH to withdraw");
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success, "ETH withdrawal failed");
        } else {
            balance = IERC20(token).balanceOf(address(this));
            require(balance > 0, "No tokens to withdraw");
            IERC20(token).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * @dev 紧急暂停（仅管理员）
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复（仅管理员）
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev 接收ETH
     */
    receive() external payable {}
}