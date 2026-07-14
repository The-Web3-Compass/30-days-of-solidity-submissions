pragma solidity ^0.8.10;
import "./UserDetails.sol";
contract PluginStorage is UserDetails{
    mapping(bytes32=>address) pluginDetails;
    function addNewPlugin(bytes32 _pluginName,address pluginAddress)public{
        require(pluginAddress!=address(0),"Wrong Address");
        pluginDetails[_pluginName]=pluginAddress;
    }
    function getPluginDetails(bytes32 _pluginName)public view returns(address){
        return pluginDetails[_pluginName];
    }
    function runPlugin(bytes32 _PluginName,string memory functionSignature,address userAddress,bytes32 achivements)external {
        address pluginAddress=pluginDetails[_PluginName];
        require(pluginAddress!=address(0),"Wrong Name");
        bytes memory data=abi.encodeWithSignature(functionSignature,userAddress,achivements);
        (bool success,)=pluginAddress.call(data);
        require(success,"Transaction Failed");
    }
    function ViewPlugin(bytes32 _PluginName,string memory functionSignature,address userAddress)external{
        address pluginAddress=pluginDetails[_PluginName];
        require(pluginAddress!=address(0),"Wrong Name");
        bytes memory data=abi.encodeWithSignature(functionSignature,userAddress);
        (bool success, bytes memory result)=pluginAddress.staticcall(data);
        (uint32 time,bytes32[] memory allAchivementsSoFar)=abi.decode(result,(uint32,bytes32[]));
    }
}