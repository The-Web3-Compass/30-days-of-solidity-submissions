(async () => {
    const messageHash = "0x5c360ebd360b9dc72729ed3d12439ddab9d31343aea833778effac0acd945725"; // 这里填 getMessageHash 得到的哈希
    const accounts = await web3.eth.getAccounts();
    const organizer = accounts[0]; // 默认第一个账户是主办方
    const signature = await web3.eth.sign(messageHash, organizer);
    console.log("Signature:", signature);
})();
