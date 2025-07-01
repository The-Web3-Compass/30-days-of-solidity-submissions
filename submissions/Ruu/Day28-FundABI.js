const{ethers} = require('ethers');

const abi = ["function withdrawEther()"];

const iface = new ethers.utils.Interface(abi);

const data = iface.encodeFunctionData("withdrawEther");

console.log(data);
