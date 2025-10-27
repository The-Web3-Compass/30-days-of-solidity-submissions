//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {

    //modifier修饰符用来保护敏感操作
    //在函数执行前检查 msg.sender 是否为 owner,否则报错
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
     
    //部署代理时你就告诉它「你的逻辑代码在哪里」
    constructor(address _logicContract) {

        //部署者自动成为管理员
        owner = msg.sender;

        //部署时传入逻辑合约地址
        logicContract = _logicContract;
    }

    //允许管理员更新 logicContract 的地址,且确保只有合约拥有者能执行
    //执行后，代理将使用新逻辑合约执行功能，而原来的数据（比如用户订阅信息）完全保留
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    //当用户调用了一个本合约中不存在的函数时,Solidity 会自动触发 fallback()
    fallback() external payable {

        //取出当前的逻辑合约地址 impl
        address impl = logicContract;

        //如果没设置逻辑地址，就报错（防止空调用）
        require(impl != address(0), "Logic contract not set");

        //内联汇编（Assembly）,用来高效控制内存、调用等操作
        assembly {

            //把用户调用的函数签名 + 参数（即 calldata）复制到内存位置 0
            calldatacopy(0, 0, calldatasize())

            //执行 delegatecall
            //执行逻辑合约里的函数
            //修改的是代理合约的存储（例如用户的订阅状态）
            //返回的结果再交给调用者
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            //把逻辑合约返回的数据复制回来（可能是执行成功的结果，也可能是错误消息）
            returndatacopy(0, 0, returndatasize())

            //如果调用失败（result == 0） → revert，回滚交易
            //否则 → 把结果返回给原调用者
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    //特殊函数，用于接收原始 ETH 转账
    //这个函数没有逻辑，只是防止 ETH 被拒收
    receive() external payable {}
}
