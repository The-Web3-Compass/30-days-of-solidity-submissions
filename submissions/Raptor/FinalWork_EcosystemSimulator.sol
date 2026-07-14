// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EcosystemSimulator is ERC20, Ownable {


    //================= Habitat Section =================//
    struct Habitat {
    bytes32 Name;
    uint8 Temperature;
    uint32 MossAmount;
    }
    mapping (bytes32 => Habitat) public Habitats;
    Habitat[] public HabitatList;
    event HabitatCreated(
        bytes32 Name,
        uint8 Temperature,
        uint32 MossAmount,
        address Creator
    );
    function addHabitat(bytes32 _name, uint8 _temperature, uint32 _mossAmount) public onlyOwner {
    Habitat memory h = Habitat({Name: _name, Temperature: _temperature, MossAmount: _mossAmount});
    HabitatList.push(h);
    Habitats[_name] = h;
    emit HabitatCreated(_name, _temperature, _mossAmount, msg.sender);
}

    //================= Creature Section =================//
    //Type 0=plants,1=herbivores,2=carnivores,3=omnivores,4=saprophagous

    struct Creature {
    bytes32 Name;
    uint8 Type;
    uint32 Size;
    uint8 SuitableTemperature;
    uint8 TemperatureAdaptability;
    address Creator;
    uint256 BirthTime;
    uint256 HabitatIndex;
    }
    Creature[] public CreatureList;
    mapping (bytes32 => Creature) public Creatures;
    mapping (uint256 => Creature) public Amount;

    event CreatureCreated(
        bytes32 Name,
        uint8 Type,
        uint32 Size,
        uint8 SuitableTemperature,
        uint8 TemperatureAdaptability,
        address Creator,
        uint256 HabitatIndex,
        uint256 Index
    );
    event CreatureEvolved(
        uint256 CreatureIndex,
        uint32 NewSize,
        uint8 NewSuitableTemperature,
        uint8 NewTemperatureAdaptability,
        uint256 Cost
    );


    function addCreature(
        bytes32 _Name,
        uint8 _Type,
        uint32 _Size,
        uint8 _SuitableTemperature,
        uint8 _TemperatureAdaptability,
        uint256 _HabitatIndex
        uint256 _amount
        ) public onlyOwner{
        require(_Type <= 4, "invalid type");
        require(_HabitatIndex < HabitatList.length, "invalid habitat index");
        require(_amount > 0, "amount must be greater than zero");

    Creature memory c = Creature({
        Name: _Name,
        Type: _Type,
        Size: _Size,
        SuitableTemperature: _SuitableTemperature,
        TemperatureAdaptability: _TemperatureAdaptability,
        Creator: msg.sender,
        BirthTime: block.timestamp,
        HabitatIndex: _HabitatIndex
    });

    CreatureList.push(c);
    Creatures[_Name] = c;
    Amount[_Name] = _amount;
    uint256 index = CreatureList.length - 1;
    emit CreatureCreated(_Name, _Type, _Size, _SuitableTemperature, _TemperatureAdaptability, msg.sender, _HabitatIndex, index);
    }

    function evolveCreature(
        uint256 _creatureIndex,
        uint32 _newSize,
        uint8 _newSuitableTemperature,
        uint8 _newTemperatureAdaptability
    ) public onlyOwner{
        require(_creatureIndex < CreatureList.length, "invalid creature index");
        uint256 cost = calculateEVP(_creatureIndex, _newSize, _newSuitableTemperature, _newTemperatureAdaptability);
        require(balanceOf(msg.sender) >= cost, "insufficient EVP balance");
        _burn(msg.sender, cost);
        
        Creature storage c = CreatureList[_creatureIndex];
        c.Size = _newSize;
        c.SuitableTemperature = _newSuitableTemperature;
        c.TemperatureAdaptability = _newTemperatureAdaptability;
        emit CreatureEvolved(_creatureIndex, _newSize, _newSuitableTemperature, _newTemperatureAdaptability, cost);
    }
    
    
    
    
    function calculateEVP(
    uint256 _creatureIndex,
    uint32 _newSize,
    uint8 _newSuitableTemperature,
    uint8 _newTemperatureAdaptability
) internal view returns(uint256) {
    require(_creatureIndex < CreatureList.length, "invalid creature index");
    
    uint256 cost = 0;
    
    uint256 sizeDiff = _newSize > CreatureList[_creatureIndex].Size 
        ? uint256(_newSize - CreatureList[_creatureIndex].Size)
        : uint256(CreatureList[_creatureIndex].Size - _newSize);
    cost += sizeDiff * 10;
    
    uint256 tempDiff = _newSuitableTemperature > CreatureList[_creatureIndex].SuitableTemperature
        ? uint256(_newSuitableTemperature - CreatureList[_creatureIndex].SuitableTemperature)
        : uint256(CreatureList[_creatureIndex].SuitableTemperature - _newSuitableTemperature);
    cost += tempDiff * 15;
    
    uint256 adaptDiff = _newTemperatureAdaptability > CreatureList[_creatureIndex].TemperatureAdaptability
        ? uint256(_newTemperatureAdaptability - CreatureList[_creatureIndex].TemperatureAdaptability)
        : uint256(CreatureList[_creatureIndex].TemperatureAdaptability - _newTemperatureAdaptability);
    cost += adaptDiff * 20;
    
    return cost;
}






//================= Token Section =================//
    error InvalidAddress();
    constructor
        (address _initialOwner,) 
            ERC20("EvolutionPoint", "EVP")
            Ownable(_initialOwner) {
        if (_collateralToken == address(0)) revert InvalidAddress();
        addHabitat("Forest",22,10000);
        addHabitat("Desert",35,200);
        addHabitat("Tundra",-10,50);

    }
    
    function mintEVP(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
    function burnEVP(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }


}