// JavaScript 前端代码async function generateSignature(attendeeAddress, contractAddress, eventName) {
// 1. 构造消息const messageHash = ethers.utils.solidityKeccak256(
        ['address', 'address', 'string'],
        [attendeeAddress, contractAddress, eventName]
    );

// 2. 组织者签名const signature = await organizerWallet.signMessage(
        ethers.utils.arrayify(messageHash)
    );

// 3. 分离签名组件const { v, r, s } = ethers.utils.splitSignature(signature);

    return { v, r, s };
}

// 使用示例const signature = await generateSignature(
    "0x742d35Cc6634C0532925a3b8D0C9964E5Bd4f071",// 参与者地址
    contractAddress,
    "Web3 Conference 2024"
);

// 调用合约签到await contract.checkInWithSignature(
    attendeeAddress,
    signature.v,
    signature.r,
    signature.s
);