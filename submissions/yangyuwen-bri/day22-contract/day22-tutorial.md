
本文档详细梳理了从0到1部署、配置并邀请同学参与区块链彩票合约的全过程，适合初学者参考。每一步都结合实际操作和常见问题，力求让每位同学都能独立完成。

## 一、准备阶段

1.  **安装和配置钱包**
    推荐使用 **MetaMask** 插件，Chrome/Edge 浏览器均可。
    创建钱包后，切换到 `Ethereum Sepolia` 测试网（如没有可在MetaMask网络列表中添加）。

2.  **获取测试币**
    访问 [Sepolia Faucet](https://sepoliafaucet.com/) 等水龙头，输入钱包地址领取测试ETH。
    每个账户都需要有足够的测试ETH才能部署和交互合约。

    易得版地址（0.05 Sepolia ETH）：https://cloud.google.com/application/web3/faucet/ethereum/sepolia

    <img width="1262" alt="截屏2025-06-25 23 18 09" src="https://github.com/user-attachments/assets/02ef7aeb-ed39-4f7c-bff4-559da06b2031" />

## 二、Chainlink VRF 订阅与LINK充值

1.  **领取测试网LINK**
    在 [Chainlink Faucet](https://faucets.chain.link/sepolia) 领取 Sepolia 测试网LINK。

2.  **创建VRF订阅**
    打开 [Chainlink VRF Subscription Manager](https://vrf.chain.link/)，连接钱包，选择 Sepolia 网络。
    点击 “Create Subscription”，填写邮箱、项目名（可选），确认创建。
    记录下 `Subscription ID`（订阅号），后续部署合约时要用。

3.  **充值LINK**
    在订阅页面点击 “Fund subscription”，用钱包充值 1-2 个 LINK 到订阅账户。

## 三、部署智能合约

1.  **打开 Remix IDE**
    访问 [Remix IDE](https://www.google.com/search?q=https://remix.ethereum.org/)，在左侧面板的 "Deploy & Run Transactions" 中，将环境（Environment）选择为 “Injected Provider - MetaMask”，确保连接的是 Sepolia 网络。

2.  **粘贴并编译合约代码**
    新建 `.sol` 文件，粘贴老师/文档提供的 `FairChainLottery` 合约代码。
    在 "Solidity Compiler" 面板，选择合适的 Solidity 版本（如 `0.8.20`），点击 “Compile”。

3.  **部署参数准备**

      * `vrfCoordinator`: `0x9ddfaca8183c41ad55329bdeed9f6a8d53168b1b` （Sepolia VRF Coordinator v2.5 地址）
      * `_subscriptionId`: 你的VRF订阅号 (例如: `11526`)
      * `_keyHash`: 从 [Chainlink官方文档](https://www.google.com/search?q=https://docs.chain.link/vrf/v2-5/supported-networks/ethereum-sepolia) 获取 Sepolia 的 Gas Lane (Key Hash)，例如: `0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae`
      * `_entryFee`: 每次购票费用，单位 Wei，例如: `1000000000000000` (即 0.001 ETH)

4.  **部署合约**
    在 Remix 的 “Deploy & Run Transactions” 面板填写上述参数，点击 “Deploy”，用 MetaMask 确认交易。
    部署成功后，在下方 "Deployed Contracts" 区域记录下你的合约地址 (例如: `0x71510649c1c47379b95fe23a33b09a8e0f7b70af`)。

## 四、Chainlink VRF订阅添加Consumer

回到 [Chainlink VRF订阅管理页面](https://vrf.chain.link/)，点击你的订阅 ID 进入详情页。
点击 “Add consumer”，粘贴你刚刚部署的合约地址，确认添加。
只有被添加为 Consumer 的合约才能请求随机数，完成公平开奖。

## 五、合约功能测试与同学参与

1.  **开启彩票**
    在 Remix 的 "Deployed Contracts" 找到你的合约，展开后点击 `startLottery` 按钮，合约拥有者点击开启新一轮彩票。

2.  **让同学参与**
    把**合约地址**、**entryFee**、**网络类型(Sepolia)** 发给同学，并附上操作指南（见下方“参与指南”）。
    同学用 MetaMask 和 Remix 连接到 Sepolia 网络，点击 `At Address` 按钮输入你的合约地址，即可加载并看到合约的交互面板。
    在 `enter` 按钮前的 `Value` 输入框填写 `1000000000000000` （或你设定的 `entryFee`），点击 `enter` 参与。

3.  **查询参与者**
    点击 `getPlayers` 按钮，可以实时查看所有参与者钱包地址的列表。

4.  **结束彩票并开奖**
    合约拥有者点击 `endLottery()`，合约会自动向 Chainlink VRF 请求随机数，开奖并将奖金发送给获胜者。
    等待几分钟后（等待VRF回调），点击 `recentWinner` 可查看中奖者地址。

## 六、常见问题与知识点总结

1.  **合约/数据会不会丢失？**
    不会。所有部署的合约和交互记录都永久保存在区块链（测试网）上。只要保存好合约地址，随时可以通过 Remix 的 “At Address” 功能或区块链浏览器（如 [Sepolia Etherscan](https://sepolia.etherscan.io/)）查看、管理和继续操作。

2.  **可以让同学随时参与吗？**
    只要彩票状态处于 “OPEN” （即 `startLottery` 后， `endLottery` 前），任何人都可以随时参与。

3.  **多账户/多同学参与怎么做？**
    MetaMask 支持创建多个账户，或者让其他同学用他们自己的钱包参与。只需保证每个参与者都在 Sepolia 网络且拥有足够的测试币即可。

4.  **测试币/Link不够怎么办？**
    可以随时去对应的水龙头（Faucet）领取，或者让已有币的同学之间相互转账。

5.  **主要知识点回顾**

      * **区块链特性**: 不可篡改与公开透明。
      * **智能合约**: 状态管理 (`enum`)、资金安全 (`payable`/`call`)、权限控制 (`onlyOwner`)。
      * **预言机 (Oracle)**: 通过 Chainlink VRF 引入链下、可验证的安全随机数。
      * **测试网**: 与主网功能一致的测试环境，操作和数据同样具有持久性。

-----

### 七、同学参与操作指南（可直接转发）

1.  确保你的 MetaMask 钱包已切换到 **Ethereum Sepolia** 测试网，并拥有足够的测试ETH。
2.  打开 [Remix IDE](https://www.google.com/search?q=https://remix.ethereum.org/)，在左侧 "Deploy & Run Transactions" 面板中，将环境选为 "Injected Provider - MetaMask"。
3.  在下方的 `At Address` 按钮旁边的输入框中，粘贴合约地址: `0x71510649c1c47379b95fe23a33b09a8e0f7b70af` (请替换为发起人给你的实际地址)，然后点击 `At Address`。
4.  在展开的合约交互面板中，找到 `enter` 函数。在其上方的 `VALUE` 输入框中填入 `1000000000000000` (这是 0.001 ETH 的 Wei 单位，请根据发起人设定的费用填写)，然后点击红色的 `enter` 按钮并确认交易。
5.  交易成功即参与成功。你可以点击 `getPlayers` 查看当前所有参与者列表，开奖后可点击 `recentWinner` 查看中奖地址。

-----

### 八、温馨提示

  * 合约部署、交互的所有历史记录，都可以通过交易哈希（Transaction Hash）或合约地址在 **[Sepolia Etherscan](https://sepolia.etherscan.io/)** 等区块链浏览器上永久查询。
  * 遇到任何问题（如无法参与、余额不足、参数报错等），请随时联系项目发起人或再次查阅本操作文档。

好的，当然可以。

这是单独为您新增的 **“合约源码验证与公开”** 这部分内容的 GitHub 适配 Markdown 格式文本。它的格式与之前的内容完全兼容。

-----

## 九、合约源码验证与公开（Etherscan 验证流程总结）

### 1\. 为什么要验证合约源码？

  * **公开透明**：让所有人都能看到你的合约源码，提升项目可信度。
  * **便于交互**：验证后，Etherscan 提供 `Read/Write Contract` 网页交互界面，无需 Remix 也能直接操作合约。
  * **方便学习和复用**：同学、老师、开发者都能直接查阅和参考你的代码。

### 2\. 验证流程详细步骤

1.  **Flatten 源码**

      * 使用 Remix (通过 Flattener 插件) 或在线工具 (如 [PoC-Contract-Flattener](https://www.google.com/search?q=https://github.com/BlockCat/contract-flattener)) 将主合约和所有依赖的合约合并成一个单独的 `.sol` 文件。
      * 在 flattened (扁平化后) 的文件顶部手动加上 SPDX License Identifier，例如： `// SPDX-License-Identifier: MIT`。
      * 确保 `pragma solidity ^0.8.XX;` 声明在文件中是清晰且唯一的。

2.  **确认编译器版本和优化参数**

      * 在 Remix 的 "Solidity Compiler" 面板，**精确记下**你部署时使用的编译器版本 (例如 `0.8.20`) 和优化参数 (Enable optimization 是否开启以及 `runs` 的数量)。
      * **注意**：Etherscan 验证时填写的参数必须与部署时**完全一致**。

3.  **获取 Constructor Arguments**

      * 在 Etherscan 的合约地址页面，切换到 “Contract” 标签页。
      * 向下滚动页面，找到 “Constructor Arguments” 部分，复制那串 ABI-encoded 的十六进制字符串。

4.  **在 Etherscan 验证合约**

      * 打开你的合约地址页面，切换到 “Contract” 标签页，点击 “Verify and Publish”。
      * **Compiler Type**: 选择 "Solidity (Single file)"。
      * **Compiler Version**: 选择你使用的**完全相同**的版本。
      * **License**: 选择与你代码中声明的 `SPDX-License-Identifier` 一致的协议。
      * 点击 "Continue"。在下一页：
          * **Contract Name**: 选择你实际部署的主合约名 (如 `FairChainLottery`)。
          * **Solidity Contract Code**: 粘贴你 **flattened** 后的全部源码。
          * **Optimization**: 根据你部署时的设置选择 Yes/No。如果开启了优化，填写相同的 `runs` 数量。
          * **Constructor Arguments**: 粘贴你之前复制的 ABI-encoded 字符串。
      * 完成人机验证，点击 “Verify and Publish”。

5.  **验证成功标志**

      * 页面出现绿色提示：“Successfully generated matching Bytecode and ABI for Contract Address”。
      * 合约页面的 “Contract” 标签页现在会出现一个绿色的对勾，并展示完整的源码、ABI 以及 `Read Contract` / `Write Contract` 功能。

### 3\. 常见问题与解决办法

| 问题 | 解决办法 |
| :--- | :--- |
| **编译器版本或优化参数不一致** | 在 Remix 和 Etherscan 上选择**完全一样**的版本和参数。 |
| **Constructor Arguments 填写错误** | 直接从 Etherscan 合约页下方复制自动生成的 ABI-encoded 字符串。 |
| **SPDX-License-Identifier 缺失** | 手动在 flattened 文件的最顶部加上 `// SPDX-License-Identifier: MIT`。 |
| **flatten 后源码不完整** | 换用其他 flatten 工具，或手动检查并合并所有 `import` 的文件。 |
| **合约名选错** | 确保选择的是你**实际部署**的主合约名，而不是它依赖的某个库或接口。 |

### 4\. 验证后的好处

  * 任何人都能在 Etherscan 上直接查阅、交互和验证你的合约。
  * 你的项目看起来更专业、更可信，便于团队协作和成果展示。
  * 方便后续写作业、做演示、让同学参与和提问。

**小结：**
合约源码验证是区块链开发的标准流程之一。虽然步骤较多，但只要 **flatten 源码**、**编译器参数设置**、**constructor arguments** 这三者都与部署时完全对齐，验证一定能成功。遇到报错时，请优先检查这三项内容。
