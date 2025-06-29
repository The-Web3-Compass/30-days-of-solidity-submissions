//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

import "./day9scientificCalculator.sol";
//在本文件夹中，另一个sol文件中，寻求可以满足用户需求的函数
//在 Solidity 里，合约名可以被当成一种类型（就像你写 uint256, address 一样）。有别的传入方法。

contract calculator{
   address public owner;//指定负责人来做一些事，比如需要owner来import另一个合约
   address public scientificCalculatoraddress;

   constructor(){
      owner =msg.sender;

   }
   modifier onlyowner(){
      require(msg.sender == owner,"only owner can do this.");
      _;
   }
   
   function setscientificCalculator(address _address) public onlyowner{
      scientificCalculatoraddress = _address;
   }
   //储存科学计算器的地址才能够call出这个contract，很重要的一步
   //还有其他方法可以call别的contract
   function add(uint256 a, uint256 b) public pure returns(uint256){
      uint256 result =a+b;
      return result;
   }
   function subtract(uint256 a ,uint256 b ) public pure returns(uint256){
      uint256 result =a-b;
      return result;
   }
   function multiply(uint256 a ,uint256 b) public pure returns(uint256){
      uint256 result =a*b;
      return result;

   }

   function divide(uint256 a, uint256 b ) public pure returns(uint256){
      require(b != 0, "cannot dicide by 0.");
      uint256 result = a/b;
      return result;
   } 
   //进行加减乘除运算
   function calculatepower(uint256 base, uint256 exponent) public view returns(uint256){
      //address cast要在这个function里面转地址 day9scientificCalculator.sol
      //这里的 MyContract(contractAddress) 就是 cast，告诉编译器：“这个地址是某个合约的实例，我要用它调用合约里的函数。”是一个把地址转换成合约的方法
     ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatoraddress);
     //import 里写文件路径 + 文件名（.sol），代码里用的是合约/接口/库名字，跟文件名没关系。
     //scientificCalc是一个遥控器，控制输入什么数字然后计算
     
    uint256 result = scientificCalc.power(base, exponent);
    return result;

}
function calculatesquareroot(uint256 _number) public  returns(uint256){
   require(_number>=0, "negative numbers are invalid.");
   //abi:application binary interface 应用程序二进制借口，高级函数solidity会自动完成二进制，但是低级的比如call就手动写
   //abi是一种通信结构，决定了合约之间的结构
   bytes memory data =abi.encodeWithSignature("squareroot(int256)", _number);
   //abi这里的签名是编码，把后面的名字和数字一起变成bytes这种字节形式
   (bool success, bytes memory returnData) = scientificCalculatoraddress.call(data);
   //把data塞进这个地址，data是上面的bytes 二进制的才能塞 要返回成功与否还有bytes塞进去回来的bytes
   require (success, "external call failed.");
   //一般要来查一下，不然不知道问题出在哪里

   uint256 result =abi.decode(returnData, (uint256));
   return result;
   //decode解码，这里的result和之前的显示不一样，因为abi编码解码了
   //把 returnData 当成一个编码了 uint256 的值的字节数组，按 uint256 格式去解码它。

   //可以把两个合约写在一起，少了import一行 剩下的操作是一样的
   


   

   

}

      



   }
   


