//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//从 OpenZeppelin 合约库中引入 IERC721 接口
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//导入 OpenZeppelin 的防重入保护合约
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    //定义市场手续费比例，类型为 uint256
    //100 表示 1%，1000 表示 10%
    uint256 public marketplaceFeePercent; 
    //定义平台手续费接收者的地址
    address public feeRecipient;

    //描述每一条 NFT 上架信息的全部细节
    struct Listing {
        address seller;     //标识当前 NFT 是由哪个用户上架出售的
        address nftAddress;     //用于区分不同系列的 NFT
        uint256 tokenId;     //与 nftAddress 一起唯一标识区块链上的一个 NFT
        uint256 price;     //表示卖家希望出售的价格
        address royaltyReceiver;     //记录创作者或版税持有者的地址，在交易时会给他们分成
        uint256 royaltyPercent;      //记录版税占售价的比例，单位也是基点
        bool isListed;     //是否已上架，true 表示当前 NFT 正在售卖中，false 表示未上架或已下架
    }

    //定义一个双层映射，存储每个 NFT 的上架信息
    //外层键是 NFT 合约地址，内层键是 tokenId，对应的值是 Listing 结构体
    mapping(address => mapping(uint256 => Listing)) public listings;

    //当 NFT 被上架时触发，事件会写入区块链日志供前端或监听程序追踪
    event Listed(
        address indexed seller,     //事件参数：卖家地址，并带有 indexed 关键字
        address indexed nftAddress,     //用于标记是哪个 NFT 合约的资产被上架
        uint256 indexed tokenId,     //用于标记是哪一个具体的 NFT 被上架
        uint256 price,     //记录上架时设定的出售价格
        address royaltyReceiver,     //记录创作者地址或将获得版税收益的账户
        uint256 royaltyPercent     //记录上架时设置的版税比例
    );

    //当买家成功购买 NFT 时触发，用于记录交易信息
    event Purchase(
        address indexed buyer,     //记录购买 NFT 的钱包地址，可通过 indexed 检索
        address indexed nftAddress,     //标明购买的 NFT 所属的合约
        uint256 indexed tokenId,     //标明具体哪一个 NFT 被购买
        uint256 price,     //记录买家实际支付的金额
        address seller,     //标明卖方是谁
        address royaltyReceiver,     //标记此次交易中应获得版税的账户
        uint256 royaltyAmount,     //记录在这次交易中支付的实际版税金额
        uint256 marketplaceFeeAmount     //记录平台从此次交易中抽取的费用
    );

    //当卖家手动取消上架时触发，通知链上和前端该 NFT 已下架
    event Unlisted(
        address indexed seller,     //让监听程序能快速筛选出某个卖家下架了哪些 NFT
        address indexed nftAddress,     //标识是哪一个 NFT 合约下的代币被下架
        uint256 indexed tokenId     //标明是哪一个具体的 NFT 被取消上架
    );

    //当市场费率或手续费接收人地址被修改时触发，用于链上记录费率更新的情况
    event FeeUpdated(
        uint256 newMarketplaceFee,     //显示修改后的费率是多少
        address newFeeRecipient     //显示修改后的手续费接收钱包地址
    );
    
    //在部署时执行一次，用来初始化市场费率和手续费接收地址
    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        //检查传入的费率参数是否大于 1000（即 10%）
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
        //检查手续费接收地址是否为零地址
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");

        //设置合约的拥有者为当前部署者
        owner = msg.sender;
        //保存市场手续费比例
        marketplaceFeePercent = _marketplaceFeePercent;
        //保存手续费收款地址
        feeRecipient = _feeRecipient;
    }

    //限制函数只能由合约所有者调用
    modifier onlyOwner() {
        //如果不是合约拥有者，则函数会立即停止执行并抛出错误信息
        require(msg.sender == owner, "Only owner");
        _;
    }

    //定义一个公开函数 setMarketplaceFeePercent，用于修改平台费率
    //仅合约拥有者可以调用
    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        //检查新费率是否超过 10%
        require(_newFee <= 1000, "Marketplace fee too high");
        //更新状态变量 marketplaceFeePercent 的值
        //修改合约的市场手续费比例
        marketplaceFeePercent = _newFee;
        //触发 FeeUpdated 事件，记录修改后的费率
        emit FeeUpdated(_newFee, feeRecipient);
    }

    //定义函数 setFeeRecipient，用于修改手续费接收者地址
    //仅合约拥有者可以调用，用于更新收款账户
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        //检查新地址不能为零地址
        require(_newRecipient != address(0), "Invalid fee recipient");
        //更新 feeRecipient 的值，保存新的收款人地址
        feeRecipient = _newRecipient;
        //触发 FeeUpdated 事件，记录新接收人
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    //卖家上架 NFT 到市场的函数，用户通过它设置出售价格、版税等信息
    function listNFT(
        address nftAddress,     //告诉市场要上架的是哪个 NFT 系列的合约
        uint256 tokenId,     //标识具体要上架的 NFT
        uint256 price,     //设置买家需要支付的金额
        address royaltyReceiver,     //设置当 NFT 被购买时应当获得版税的人
        uint256 royaltyPercent     //设置卖家希望创作者获得的分成比例
    ) external {     //函数修饰符 external，表示该函数可被外部账户或合约直接调用
        require(price > 0, "Price must be above zero");     //检查价格是否大于 0
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");     //检查版税比例不能超过 1000（即 10%）
        require(!listings[nftAddress][tokenId].isListed, "Already listed");     //检查该 NFT 是否已经上架

        //创建一个 IERC721 类型的变量 nft，用来代表该地址的 NFT 合约
        IERC721 nft = IERC721(nftAddress);
        //检查调用者是否是真正的 NFT 拥有者
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        //开始一个多行的 require 检查
        //用于检查市场是否被卖家授权操作该 NFT
        require(
            //条件：NFT 的单个 token 授权给市场合约，或者卖家已给市场“全部授权”
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"     //报错
        );

        //创建并存入一个 Listing 结构体实例到映射中
        //在 listings 映射里登记这次上架的 NFT 信息
        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,     //记录是谁上架了这件 NFT
            nftAddress: nftAddress,     //记录该上架信息对应的合约
            tokenId: tokenId,     //记录是哪一个 NFT
            price: price,     //记录上架时设定的售价
            royaltyReceiver: royaltyReceiver,     //记录创作者或指定接收分成的账户
            royaltyPercent: royaltyPercent,     //记录应付的版税比例
            isListed: true     //标识该 NFT 当前处于“已上架”状态
        });

        //触发 Listed 事件
        //把上架行为记录到区块链日志中，供前端或其他系统监听更新
        emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);
    }

    //让买家购买已经上架的 NFT
    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        //从映射中读取该 NFT 的 Listing 数据，保存在内存变量 item 中
        //获取这件上架 NFT 的完整信息（卖家、价格、版税等）
        Listing memory item = listings[nftAddress][tokenId];
        //防止购买未上架或已被下架的 NFT
        require(item.isListed, "Not listed");
        //检查买家发送的 ETH 是否等于 NFT 的标价
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            //条件：版税比例 + 平台手续费比例必须小于或等于 10000（即 100%）
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"     //报错
        );

        //计算市场手续费金额
        //用买家支付的总价 × 平台费率 ÷ 10000 得出平台应收的 ETH 数量
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        //计算应支付的版税金额
        //买家支付的总价 × 版税比例 ÷ 10000 得出应给创作者的分成
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        //计算卖家最终能拿到的金额
        //从总价中扣除平台手续费和版税，剩余部分是卖家净收入
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        //检查是否需要收取平台费
        //如果平台费为 0（例如暂时免手续费），就跳过转账
        if (feeAmount > 0) {
            //向 feeRecipient 地址转账平台手续费
            payable(feeRecipient).transfer(feeAmount);
        }

        //创作者版税支付逻辑
        //条件判断，只有当版税大于 0 且接收人地址有效时才执行支付
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            //向版税接收者转账版税金额，即给创作者或指定地址发放应得版税
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        //向卖家转账剩余的金额，把扣完手续费和版税后的资金发给卖家
        payable(item.seller).transfer(sellerAmount);

        //调用 ERC721 合约的 safeTransferFrom 函数，将 NFT 从卖家转移给买家
        //safeTransferFrom 会进行安全检查，确保接收方是能够接收 NFT 的钱包或合约
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        //删除映射中的该 NFT 上架记录
        //节省存储空间，防止被重复购买
        delete listings[nftAddress][tokenId];

        //触发 Purchase 事件
        //记录交易完成的详细信息到链上日志中，供前端显示或追踪
        emit Purchase(
            msg.sender,     //记录是谁购买的
            nftAddress,     //记录是哪一个系列的 NFT
            tokenId,     //记录买的具体是哪一件 NFT
            msg.value,     //记录买家实际支付的 ETH 总额
            item.seller,     //记录卖方是谁
            item.royaltyReceiver,     //记录分成的接收者
            royaltyAmount,     //记录创作者获得了多少钱
            feeAmount     //记录平台从该笔交易中抽取的费用
        );
    }

    //声明一个公开函数 cancelListing，用于取消 NFT 的上架
    //允许卖家在 NFT 被卖出前，手动下架它
    function cancelListing(address nftAddress, uint256 tokenId) external {
        //从存储中读取该 NFT 的 Listing 信息到内存中
        Listing memory item = listings[nftAddress][tokenId];
        //检查该 NFT 是否真的处于上架状态
        require(item.isListed, "Not listed");
        //验证调用者是不是该 NFT 的卖家
        require(item.seller == msg.sender, "Not the seller");

        //从映射中删除该 NFT 的上架记录
        //取消上架后，合约中不再保存此 NFT 的出售信息
        //delete 是 Solidity 的关键字，用于清除映射中的数据并释放存储空间
        delete listings[nftAddress][tokenId];
        //向区块链日志记录这次下架行为，前端或监听程序可据此更新状态
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    //允许外部用户或前端查看某个 NFT 当前的上架详情
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        //从映射中返回指定 NFT 的 Listing 信息
        //让外部可以读取该 NFT 的价格、卖家、版税比例等
        return listings[nftAddress][tokenId];
    }

    //定义一个 receive 函数
    //这是 Solidity 的特殊函数，当合约直接接收到 ETH（例如 send、transfer、call 不带数据时）时被触发
    //修饰符 external payable 允许它被外部调用并接收 ETH
    receive() external payable {
        //当有人直接向合约转账 ETH 时，立即回退交易并提示错误信息
        revert("Direct ETH not accepted");
    }

    //当调用合约中不存在的函数，或调用时携带数据但没有对应函数时触发
    fallback() external payable {
        //在 fallback 函数中直接回退交易
        revert("Unknown function");
    }
}
