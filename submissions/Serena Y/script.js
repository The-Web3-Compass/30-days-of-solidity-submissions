// 注意：Remix 环境中不需要 require('ethers')
// 假设您已经成功部署了 DecentralizedGovernance 合约，并将其加载到变量 daoContract

// 1. 定义目标和数据
const targetAddress = "0xfdDA7D1bD796FfD790d43CFE3104938A7Ed3A3eB";
const calldata = "0x3ccfd60b"; // withdrawEther() 的编码数据

// 2. 封装成数组
const executionTargets = [targetAddress];
const executionData = [calldata];

console.log("Targets 数组:", executionTargets);
console.log("Data 数组:", executionData);

// 3. 调用 createProposal（仅供参考，实际调用需要连接钱包）
// try {
//     const proposalTx = await daoContract.createProposal(
//         "提取ETH提案", 
//         executionTargets, 
//         executionData
//     );
//     console.log("提案交易哈希:", proposalTx.hash);
// } catch(e) {
//     console.error("调用失败:", e.message);
// }