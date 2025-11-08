// SPDX-License-Identifier:MIT
// SPDX-License-Identifier是Solidity 0.6.8版本引入的一个注释，用于声明智能合约的许可证类型。这里使用的是MIT许可证，这是一种非常宽松的开源许可证，允许用户自由使用、修改和分发代码。

pragma solidity ^0.8.0;
// 指定编译器版本，表示这段代码需要使用Solidity 0.8.0或更高版本进行编译。版本号的约束确保代码在兼容的编译器版本上运行。

contract ClickCounter {
    // 定义一个名为ClickCounter的智能合约。合约是Solidity中用于封装逻辑和数据的基本单元，类似于面向对象编程中的类。

    uint256 public counter;
    // 定义一个uint256类型的变量counter，用于存储点击次数。uint256是Solidity中的一种无符号整数类型，范围为0到2^256-1。public关键字表示这个变量是公开的，外部合约或用户可以通过合约地址访问它的值。

    function click() public {
        // 定义一个名为click的公共函数。public关键字表示这个函数可以被外部调用。
        counter++;
        // 每次调用click函数时，counter变量的值会增加1。这是通过Solidity的自增运算符++实现的。
    }
}