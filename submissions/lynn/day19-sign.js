(async () => {
  const messageHash = "0x9e8897fdbfc3c8d97e7f7478465a2e2ee7b5f75534c09e5d949efbc8dd410270";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();

// 在浏览器控制台执行
const messageHash = "0x9e8897fdbfc3c8d97e7f7478465a2e2ee7b5f75534c09e5d949efbc8dd410270";  // 从合约获取的哈希
const signature = await ethereum.request({
    method: "personal_sign",
    params: [messageHash, ethereum.selectedAddress]
});