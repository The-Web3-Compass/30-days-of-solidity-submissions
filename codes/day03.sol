// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidateNames(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] += 1;
    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}
----
非常好的问题。这个地方其实是 Solidity 里一个非常核心的类型机制，我们可以一步步拆开来看👇

---

## 🧩 一、`mapping(string => uint256)` 的结构

这个语句的意思是：

> 建立一个“**映射关系**（mapping）”，把一个 `string` 类型的键（key）对应到一个 `uint256` 类型的值（value）。

也就是：

```solidity
mapping(string => uint256) public votes;
```

意思是：

> 用候选人的名字（字符串）去查找他目前的票数（一个整数）。

---

## 🧮 二、那 `uint256` 是什么？

`uint256` 是 Solidity 中的一种**数值类型**，它表示：

> **Unsigned Integer (无符号整数)，占用256位（bits）空间。**

### 具体解释：

* **Unsigned（无符号）**：表示这个整数**没有负号**，只能是 0 或正数。
* **256 位（bits）**：表示它可以存储的最大值非常大：

  [
  2^{256} - 1 = 115792089237316195423570985008687907853269984665640564039457584007913129639935
  ]
  （这是个接近 (10^{77}) 的天文数字 😄）

---

## 📘 三、为什么 Solidity 要用 `uint256` 而不是 `int` 或其他类型？

主要原因有三个：

1. **区块链的精度和兼容性**

   * 以太坊虚拟机（EVM）在底层处理整数时是以 256 位为单位的。
   * 所以使用 `uint256` 是最自然、最高效的选择。

2. **没有负票数的逻辑**

   * 投票系统不可能出现负数的票数。
   * 因此使用无符号整数（`uint`）最合理。

3. **节省 Gas / 避免错误**

   * 使用固定类型（例如 `uint256`）可以减少类型转换错误。
   * 在大多数情况下，`uint` 默认等价于 `uint256`。

---

## 📊 四、举个例子：

假设我们写：

```solidity
mapping(string => uint256) public votes;
```

* `string` = “Alice”
* `uint256` = 5

那这个结构里大概可以理解为：

```text
votes = {
  "Alice": 5,
  "Bob": 3
}
```

类似 Python 字典：

```python
votes = {"Alice": 5, "Bob": 3}
```

---

## 💡 小结：

| 概念                           | 含义                        |
| ---------------------------- | ------------------------- |
| `string`                     | 键（key）类型，表示候选人的名字         |
| `uint256`                    | 值（value）类型，表示候选人的票数（非负整数） |
| `mapping(string => uint256)` | 用字符串到整数的映射表               |
| 为什么用 uint256                 | 因为EVM底层是256位结构，且投票不需要负数   |

---

要不要我顺便帮你列一个对比表，说明 Solidity 常见的数值类型（`uint8`, `uint16`, `uint256`, `int256`）分别能表示什么范围？
