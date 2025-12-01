/**
 * @title 构建你的第一个智能合约 - ClickCounter计数器
 * @description 
 *   💡 想象一下：
 *   创建一个数字点击器，每次有人点击，区块链上的数字就会+1！这就是我们即将构建的智能合约 ✨
 *
 *   🛠 你将亲手实现：
 *  - 声明一个计数器变量
 *  - 创建 click() 函数让数字+1
 *  - 创建 unclick() 函数让数字-1
 *  - 部署到测试网，真实体验交互！
 */

// SPDX-License-Identifier: MIT
/*
SPDX标准中，代表软件包数据交换，它只是在代码中代表许可证的一种正式方式
MIT的许可证标识符：这是Solidity智能合约的标准开头，几乎所有的开源智能合约都会包含这样的许可证声明
非常宽松：允许自由使用、修改、分发
只需保留版权声明：使用时需要包含原始版权声明
商业友好：可以用于商业项目
*/

pragma solidity ^0.8.0;
// 指定本智能合约源码需要使用的Solidity编译器的版本，要求不能低于0.8.0版本，但低于0.9.0版本。
// 它的作用是确保合约使用的编译器版本支持所用到的新特性和安全性修复，避免因不同版本之间的不兼容导致的合约错误或漏洞。

contract ClickCounter {
// 声明智能合约的地方

    uint256 public clickCount = 0;
    // 声明一个无符号整数类型的变量clickCount，初始值为0，任何人都可以访问这个变量，因为使用public修饰符

    function click() public {
      clickCount += 1;
    }

    function unclick() public {
      clickCount -= 1;
    }
}
