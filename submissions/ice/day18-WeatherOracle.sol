/**
 * @title WeatherOracle
 * @dev 农作物保险合同
 * 为农民提供保险服务。
 * 功能点：
 * 1. 使用 Chainlink Functions 和 Open-Meteo API 检索实时天气数据。
 * 2. 如果生长季节的降雨量低于特定阈值，农民可以申请保险
 * 3. 保险条件达成情况下，自动触发支付
 * 安全地将外部数据集成到合约逻辑。Interacting with oracles /fetching off-chain data
 */
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title FunctionsClient
 * @dev 简化版的Chainlink Functions客户端接口
 */
interface FunctionsClient {
    function executeRequest(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit
    ) external returns (bytes32);
}

/**
 * @title FunctionsOracle
 * @dev 简化版的Chainlink Functions预言机接口
 */
interface FunctionsOracle {
    function getRegistry() external view returns (address);
}

/**
 * @title LinkTokenInterface
 * @dev LINK代币接口
 */
interface LinkTokenInterface {
    function transfer(address to, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimalPlaces);
}

/**
 * @title WeatherOracle
 * @dev 使用Chainlink Functions和Open-Meteo API获取天气数据的农作物保险合约
 */
contract WeatherOracle {
    // 保险状态
    enum InsuranceState { NotPurchased, Active, Claimed, Expired }
    
    // 保险信息
    struct Insurance {
        address farmer;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startDate;
        uint256 endDate;
        string location; // 格式: "latitude,longitude"
        uint256 minRainfall; // 最低降雨量阈值（毫米）
        InsuranceState state;
        uint256 actualRainfall; // 实际降雨量
    }
    
    // 保险ID到保险信息的映射
    mapping(uint256 => Insurance) public insurances;
    
    // 农民地址到保险ID的映射
    mapping(address => uint256[]) public farmerInsurances;
    
    // 保险计数器
    uint256 private insuranceCounter;
    
    // Chainlink Functions相关变量
    FunctionsOracle private oracle;
    uint64 private subscriptionId;
    uint32 private gasLimit;
    address private linkToken;
    
    // 保险请求到保险ID的映射
    mapping(bytes32 => uint256) private requestToInsuranceId;
    
    // 合约所有者
    address public owner;
    
    // JavaScript源代码 - 用于调用Open-Meteo API
    string private weatherRequestSource = "const latitude = args[0];"
                                        "const longitude = args[1];"
                                        "const startDate = args[2];"
                                        "const endDate = args[3];"
                                        "const url = `https://archive-api.open-meteo.com/v1/archive?latitude=${latitude}&longitude=${longitude}&start_date=${startDate}&end_date=${endDate}&daily=precipitation_sum&timezone=UTC`;"
                                        "const weatherRequest = Functions.makeHttpRequest({"
                                        "  url: url"
                                        "});"
                                        "const weatherResponse = await weatherRequest;"
                                        "if (weatherResponse.error) {"
                                        "  throw Error('Request failed');"
                                        "}"
                                        "const precipitation = weatherResponse.data.daily.precipitation_sum;"
                                        "let totalRainfall = 0;"
                                        "for (let i = 0; i < precipitation.length; i++) {"
                                        "  totalRainfall += precipitation[i] || 0;"
                                        "}"
                                        "return Functions.encodeUint256(Math.round(totalRainfall * 10));"; // 转换为毫米并四舍五入
    
    // 事件
    event InsurancePurchased(uint256 indexed insuranceId, address indexed farmer, uint256 premium, uint256 coverageAmount);
    event RainfallDataRequested(uint256 indexed insuranceId, bytes32 indexed requestId);
    event RainfallDataReceived(uint256 indexed insuranceId, uint256 rainfall);
    event InsuranceClaimed(uint256 indexed insuranceId, address indexed farmer, uint256 amount);
    event InsuranceExpired(uint256 indexed insuranceId);
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _oracle Chainlink Functions预言机地址
     * @param _subscriptionId Chainlink Functions订阅ID
     * @param _gasLimit 调用Chainlink Functions的gas限制
     * @param _link LINK代币地址
     */
    constructor(address _oracle, uint64 _subscriptionId, uint32 _gasLimit, address _link) {
        owner = msg.sender;
        oracle = FunctionsOracle(_oracle);
        subscriptionId = _subscriptionId;
        gasLimit = _gasLimit;
        linkToken = _link;
        insuranceCounter = 1; // 从1开始计数
    }
    
    /**
     * @dev 购买保险
     * @param _latitude 农场纬度
     * @param _longitude 农场经度
     * @param _startDate 保险开始日期（格式：YYYY-MM-DD）
     * @param _endDate 保险结束日期（格式：YYYY-MM-DD）
     * @param _minRainfall 最低降雨量阈值（毫米）
     * @return 保险ID
     */
    function purchaseInsurance(
        string memory _latitude,
        string memory _longitude,
        string memory _startDate,
        string memory _endDate,
        uint256 _minRainfall
    ) external payable returns (uint256) {
        require(msg.value > 0, "Premium must be greater than 0");
        require(_minRainfall > 0, "Minimum rainfall must be greater than 0");
        
        // 验证日期格式（简化版）
        require(bytes(_startDate).length == 10, "Invalid start date format");
        require(bytes(_endDate).length == 10, "Invalid end date format");
        
        // 计算保险金额（保费的3倍）
        uint256 coverageAmount = msg.value * 3;
        
        // 创建位置字符串 (latitude,longitude)
        string memory location = string(abi.encodePacked(_latitude, ",", _longitude));
        
        // 创建新保险
        uint256 insuranceId = insuranceCounter++;
        insurances[insuranceId] = Insurance({
            farmer: msg.sender,
            premium: msg.value,
            coverageAmount: coverageAmount,
            startDate: block.timestamp,
            endDate: block.timestamp + 90 days, // 默认3个月
            location: location,
            minRainfall: _minRainfall,
            state: InsuranceState.Active,
            actualRainfall: 0
        });
        
        // 添加到农民的保险列表
        farmerInsurances[msg.sender].push(insuranceId);
        
        emit InsurancePurchased(insuranceId, msg.sender, msg.value, coverageAmount);
        
        return insuranceId;
    }
    
    /**
     * @dev 请求降雨量数据
     * @param _insuranceId 保险ID
     * @return requestId Chainlink Functions请求ID
     */
    function requestRainfallData(uint256 _insuranceId) external returns (bytes32) {
        Insurance storage insurance = insurances[_insuranceId];
        
        require(insurance.farmer == msg.sender || owner == msg.sender, "Not authorized");
        require(insurance.state == InsuranceState.Active, "Insurance not active");
        
        // 解析位置
        string[] memory locationParts = split(insurance.location, ",");
        require(locationParts.length == 2, "Invalid location format");
        
        // 准备Open-Meteo API参数
        string[] memory args = new string[](4);
        args[0] = locationParts[0]; // latitude
        args[1] = locationParts[1]; // longitude
        args[2] = "2023-01-01"; // 示例开始日期，实际应用中应从保险信息中提取
        args[3] = "2023-01-31"; // 示例结束日期，实际应用中应从保险信息中提取
        
        // 调用Chainlink Functions
        bytes32 requestId = FunctionsClient(address(oracle)).executeRequest(
            weatherRequestSource, // JavaScript源代码
            new bytes(0), // 无秘密参数
            args, // API参数
            subscriptionId, // 订阅ID
            gasLimit // Gas限制
        );
        
        // 存储请求ID到保险ID的映射
        requestToInsuranceId[requestId] = _insuranceId;
        
        emit RainfallDataRequested(_insuranceId, requestId);
        
        return requestId;
    }
    
    /**
     * @dev Chainlink Functions回调函数
     * @param requestId 请求ID
     * @param result 结果数据
     * @param err 错误信息
     */
    function fulfillRequest(bytes32 requestId, bytes memory result, bytes memory err) external {
        // 在实际应用中，应该验证调用者是否为预言机
        // require(msg.sender == oracle.getRegistry(), "Only oracle can fulfill");
        
        // 检查是否有错误
        require(err.length == 0, "Error in Chainlink Functions response");
        
        // 解析降雨量数据（毫米）
        uint256 rainfall = abi.decode(result, (uint256)) / 10; // 转换回实际毫米数
        
        uint256 insuranceId = requestToInsuranceId[requestId];
        require(insuranceId > 0, "Request ID not found");
        
        Insurance storage insurance = insurances[insuranceId];
        require(insurance.state == InsuranceState.Active, "Insurance not active");
        
        // 更新实际降雨量
        insurance.actualRainfall = rainfall;
        
        emit RainfallDataReceived(insuranceId, rainfall);
        
        // 如果降雨量低于阈值，自动触发赔付
        if (rainfall < insurance.minRainfall) {
            processClaim(insuranceId);
        }
    }
    
    /**
     * @dev 处理保险索赔
     * @param _insuranceId 保险ID
     */
    function processClaim(uint256 _insuranceId) internal {
        Insurance storage insurance = insurances[_insuranceId];
        
        require(insurance.state == InsuranceState.Active, "Insurance not active");
        require(insurance.actualRainfall < insurance.minRainfall, "Rainfall above threshold");
        
        // 更新保险状态
        insurance.state = InsuranceState.Claimed;
        
        // 转账赔付金额
        payable(insurance.farmer).transfer(insurance.coverageAmount);
        
        emit InsuranceClaimed(_insuranceId, insurance.farmer, insurance.coverageAmount);
    }
    
    /**
     * @dev 手动触发保险索赔（仅限合约所有者）
     * @param _insuranceId 保险ID
     */
    function manualClaim(uint256 _insuranceId) external onlyOwner {
        Insurance storage insurance = insurances[_insuranceId];
        
        require(insurance.state == InsuranceState.Active, "Insurance not active");
        
        // 更新保险状态
        insurance.state = InsuranceState.Claimed;
        
        // 转账赔付金额
        payable(insurance.farmer).transfer(insurance.coverageAmount);
        
        emit InsuranceClaimed(_insuranceId, insurance.farmer, insurance.coverageAmount);
    }
    
    /**
     * @dev 保险过期（仅限合约所有者）
     * @param _insuranceId 保险ID
     */
    function expireInsurance(uint256 _insuranceId) external onlyOwner {
        Insurance storage insurance = insurances[_insuranceId];
        
        require(insurance.state == InsuranceState.Active, "Insurance not active");
        require(block.timestamp > insurance.endDate, "Insurance period not ended");
        
        // 更新保险状态
        insurance.state = InsuranceState.Expired;
        
        emit InsuranceExpired(_insuranceId);
    }
    
    /**
     * @dev 获取农民的所有保险ID
     * @param _farmer 农民地址
     * @return 保险ID数组
     */
    function getFarmerInsurances(address _farmer) external view returns (uint256[] memory) {
        return farmerInsurances[_farmer];
    }
    
    /**
     * @dev 获取保险详情
     * @param _insuranceId 保险ID
     * @return farmer 农民地址
     * @return premium 保费
     * @return coverageAmount 保险金额
     * @return startDate 开始日期
     * @return endDate 结束日期
     * @return location 位置
     * @return minRainfall 最低降雨量阈值
     * @return state 保险状态
     * @return actualRainfall 实际降雨量
     */
    function getInsuranceDetails(uint256 _insuranceId) external view returns (
        address farmer,
        uint256 premium,
        uint256 coverageAmount,
        uint256 startDate,
        uint256 endDate,
        string memory location,
        uint256 minRainfall,
        InsuranceState state,
        uint256 actualRainfall
    ) {
        Insurance storage insurance = insurances[_insuranceId];
        return (
            insurance.farmer,
            insurance.premium,
            insurance.coverageAmount,
            insurance.startDate,
            insurance.endDate,
            insurance.location,
            insurance.minRainfall,
            insurance.state,
            insurance.actualRainfall
        );
    }
    
    /**
     * @dev 更新Chainlink Functions参数（仅限合约所有者）
     * @param _oracle 新的预言机地址
     * @param _subscriptionId 新的订阅ID
     * @param _gasLimit 新的gas限制
     */
    function updateOracleParameters(address _oracle, uint64 _subscriptionId, uint32 _gasLimit) external onlyOwner {
        oracle = FunctionsOracle(_oracle);
        subscriptionId = _subscriptionId;
        gasLimit = _gasLimit;
    }
    
    /**
     * @dev 更新JavaScript源代码（仅限合约所有者）
     * @param _source 新的JavaScript源代码
     */
    function updateRequestSource(string memory _source) external onlyOwner {
        weatherRequestSource = _source;
    }
    
    /**
     * @dev 提取合约余额（仅限合约所有者）
     * @param _amount 提取金额
     */
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(_amount);
    }
    
    /**
     * @dev 提取LINK代币（仅限合约所有者）
     * @param _amount 提取金额
     */
    function withdrawLink(uint256 _amount) external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkToken);
        require(link.transfer(msg.sender, _amount), "Unable to transfer LINK");
    }
    
    /**
     * @dev 辅助函数：按分隔符分割字符串
     * @param _str 要分割的字符串
     * @param _delimiter 分隔符
     * @return 分割后的字符串数组
     */
    function split(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory str = bytes(_str);
        bytes memory delimiter = bytes(_delimiter);
        
        uint count = 1;
        for(uint i = 0; i < str.length; i++) {
            if(keccak256(abi.encodePacked(substring(str, i, delimiter.length))) == keccak256(abi.encodePacked(_delimiter))) {
                count++;
                i += delimiter.length - 1;
            }
        }
        
        string[] memory parts = new string[](count);
        
        uint start = 0;
        uint partIndex = 0;
        for(uint i = 0; i <= str.length; i++) {
            if(i == str.length || keccak256(abi.encodePacked(substring(str, i, delimiter.length))) == keccak256(abi.encodePacked(_delimiter))) {
                parts[partIndex] = substring(_str, start, i - start);
                partIndex++;
                if(i < str.length) {
                    i += delimiter.length - 1;
                    start = i + 1;
                }
            }
        }
        
        return parts;
    }
    
    /**
     * @dev 辅助函数：获取字符串的子串
     * @param _str 原字符串
     * @param _start 起始位置
     * @param _length 长度
     * @return 子串
     */
    function substring(bytes memory _str, uint _start, uint _length) internal pure returns (bytes memory) {
        require(_start + _length <= _str.length, "Substring out of bounds");
        
        bytes memory result = new bytes(_length);
        for(uint i = 0; i < _length; i++) {
            result[i] = _str[_start + i];
        }
        
        return result;
    }
    
    /**
     * @dev 辅助函数：获取字符串的子串
     * @param _str 原字符串
     * @param _start 起始位置
     * @param _length 长度
     * @return 子串
     */
    function substring(string memory _str, uint _start, uint _length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        return string(substring(strBytes, _start, _length));
    }
    
    /**
     * @dev 接收ETH的回退函数
     */
    receive() external payable {}
}

/**
 * @title MockWeatherOracle
 * @dev 用于测试的模拟天气预言机合约
 */
contract MockWeatherOracle {
    WeatherOracle public weatherInsurance;
    
    /**
     * @dev 构造函数
     * @param _weatherInsurance WeatherOracle合约地址
     */
    constructor(address payable _weatherInsurance) {
        weatherInsurance = WeatherOracle(_weatherInsurance);
    }
    
    /**
     * @dev 模拟发送降雨量数据
     * @param _requestId Chainlink Functions请求ID
     * @param _rainfall 降雨量（毫米）
     */
    function mockFulfillRequest(bytes32 _requestId, uint256 _rainfall) external {
        // 编码降雨量数据
        bytes memory result = abi.encode(_rainfall * 10); // 模拟Chainlink Functions的返回格式
        bytes memory err = new bytes(0); // 无错误
        
        // 调用WeatherOracle合约的fulfillRequest函数
        (bool success, ) = address(weatherInsurance).call(
            abi.encodeWithSignature("fulfillRequest(bytes32,bytes,bytes)", _requestId, result, err)
        );
        require(success, "Callback failed");
    }
}

