**教程随写**
https://zd536d2ua0.feishu.cn/docx/R74mdhPE8oUpR6xg5PhcpHGgnwh

**remix使用**
网站：https://remix.ethereum.org/

1. 工作空间中新建名为ClickCounter.sol的文件
2. 写代码
3. 在deploy&run transaction里部署后，可以执行
![image](https://github.com/user-attachments/assets/f718c741-b546-4990-b12d-4dacf108705f)


**remix连接github（待接入）**
![image](https://github.com/user-attachments/assets/8e03b5f5-3983-49ef-b7ce-749c8e418b83)


**GitHub本地连接远端仓库**
参考文档: https://zd536d2ua0.feishu.cn/docx/R74mdhPE8oUpR6xg5PhcpHGgnwh

**每日代码操作学习笔记**
Day04
账户代表进入不同的address。
1. 部署之前需要先填写拍卖品和拍卖结束时间，如"painting",300，点击部署，此时拍卖开始
2. 点击auctionEndTime，可以看到拍卖结束时间，时间戳可以转化为我们需要的时间
3. 点击bid，可以进行出价，输入价格，点击bid，此时可以查看到出价，出价成功后，可以查看到出价者，出价者可以查看到自己出价成功的拍卖品
4. 在上方账户切换账户，可以切换到其他账户，进行出价，出价成功后，可以查看到出价者，出价者可以查看到自己出价成功的拍卖品
5. 当拍卖结束时间到之后，手动点击endAuction，可以结束拍卖
6. 点击getWinner，可以查看拍卖品最终的归属者

Day05
1. 部署，并且自动会录入当前启动部署的address为owner
2. 输入金额，点击addTreasure，可以存钱，只有owner可以存钱
3. 输入金额，点击withdrawTreasure，owner可以直接取钱，其他人需要进入判断模式
4. 选择上面的某一个账户，点击approveWithdrawal和金额，表示允许该用户取钱的金额
5. 切换到这个账户上，withdrawTreasure可以取钱，只能在允许的额度内取钱，取完一次会自动标记已取钱
6. 只有owner账户可以将这个账户的标记reset成false，这个账户才能继续取钱
7. 只有owner可以transfer owner账户，将owner账户转移给其他账户

Day06
1. 部署，并且自动会录入当前启动部署的address为bankManager
2. 点击addMembers，可以增加成员，只有bankManager可以增加成员
3. 点击getMembers，可以查看当前成员列表
4. 点击depositAmount，可以存钱，只有注册用户可以存钱
5. 点击withdrawAmount，可以取钱，只有注册用户可以取钱
6. 点击getBalance，可以查看当前账户余额
7. 点击getSender，可以查看当前账户地址
8. 真实ETH测试，将depositEther设置为payable，remix中的按钮会变红
9. 在相应的账户之下，可以输入金额，点击depositEther，可以存入真实的ETH

// owner：0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// address 1：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

Day07
1. 在owner的账户下点击部署，并初始化array和map
2. 增加address1为friend，在列表中
3. 记录friend欠自己的钱，写入其地址和金额，记录debts
4. 切换到address1账户下，充值金额（payable），写入owner地址和还钱金额，debts会一起更新
5. debts只是用来记账，可以使用transfer或call函数直接转账即可

Day08
1. 部署之后自动录入USD等四个币种
2. tipInCurrency是payable的，填入一定的数额和币种之后，需要自己换算再填入账户以太币中心，要不然会报错
3. 其他都比较好懂

Day09
1. 两个函数都部署，在ScientificCalculator.sol上复制一下地址，粘贴进主函数的地址中
2. 其他可以直接计算，其中squareRoot由于data被迁移到另外一个合约的地址，无法使用view声明，因此在结果上会显示在监听端
3. 我增加了一个函数为calculateSquareRootDirect，使用了和power相同的方法，也可以实现，并且可以使用view

Day10
1. 部署合约，注册用户，在当前address下录入名称信息和体重信息
2. 当记录workout、更新体重时，在输出侧的日志中会有相应的event输出，注意即可

Day11
1. 实际上是完成了一个对ownalbe的继承：contract VaultMaster is Ownable，但是这里可以进行一些改动
2. 其他操作较为简单，基本上是存取款操作

day13
1. 这里的constructor继承了前一天的mytoken函数，因此包括了之前的声明，需要更改两个函数为virtual
2. **目前还存在疑问：token和金额之间的关系是什么？为什么会每次购买token获取的金额不一样且没有什么规律**