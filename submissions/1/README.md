## 合约文件  
- `ClickCounter.sol`：实现计数器的加减和重置功能。
- `SaveMyName.sol`：实现在区块链上存储和检索数据功能。
- `PollStation.sol`：一个投票站，学会数组`uint[]`、映射`mapping(address => uint)`的使用。
- `AuctionHouse.sol`：根据条件和时间控制逻辑,'if/else'、'block.timestamp'。
- `AdminOnly.sol`：使用 'modifier' 和 'msg.sender' 创建具有受限访问权限的合同，管理员权限。
- `EtherPiggyBank.sol`：管理余额（使用“address”来识别用户）和跟踪谁发送了以太币（使用“msg.sender”），就像区块链上的一个简单银行账户，演示了如何处理以太币和用户地址。
- `SimpleIOU.sol`：使用 'payable' 接受真实的以太币，在地址之间转移资金，以及使用嵌套映射来表示 'Alice owes Bob' 等关系。该合约反映了现实世界的借贷，如何在 Solidity 中对这些交互进行建模。
