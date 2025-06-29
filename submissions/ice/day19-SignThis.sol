/**
 * @title SignThis
 * @dev 加密身份验证
 * 功能点：
 * 1. 生成消息哈希
 * 2. 验证链上签名
 * 3. 使用"ecrecover"恢复签名者地址
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title SignThis
 * @dev 基于签名验证的简单合约
 */
contract SignThis {
    // 合约所有者
    address public owner;
    
    // 事件
    event MessageVerified(address indexed signer, address indexed claimer, bool success);
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev 生成消息哈希
     * @param _message 消息内容
     * @return 消息哈希
     */
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }
    
    /**
     * @dev 生成以太坊签名消息哈希
     * @param _messageHash 原始消息哈希
     * @return 以太坊签名消息哈希
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    /**
     * @dev 从签名中恢复签名者地址
     * @param _ethSignedMessageHash 以太坊签名消息哈希
     * @param _signature 签名
     * @return 签名者地址
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        // 从签名中提取r, s, v
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        
        // 如果签名使用了EIP-155，需要调整v值
        if (v < 27) {
            v += 27;
        }
        
        // 使用ecrecover恢复签名者地址
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    /**
     * @dev 验证签名
     * @param _message 原始消息
     * @param _signature 签名
     * @param _signer 声称的签名者
     * @return 签名是否有效
     */
    function verify(string memory _message, bytes memory _signature, address _signer) public returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        
        bool isValid = recoverSigner(ethSignedMessageHash, _signature) == _signer;
        
        emit MessageVerified(_signer, msg.sender, isValid);
        
        return isValid;
    }
    /**
     * 调试方法
     * _message 会议主办方给每个用户单独发送原始消息
     *  getMessageHash(_message) 生成消息哈希_messageHash
     *  （1）用户使用自己的私钥对_messageHash进行签名得到_signature 签名（在remix中入口在account右边的编辑按钮进去）
     *  （2）主办方使用getEthSignedMessageHash（_messageHash）得到_ethSignedMessageHash
             使用recoverSigner(_ethSignedMessageHash,_signature)可以还原出用户地址_signer
     * 使用场景
     * 当与会者到达时，将收到的消息_message,自己私钥签名结果_signature，自己的地址_signer提交给verify，返回true证明确实受到了邀请
     */
}