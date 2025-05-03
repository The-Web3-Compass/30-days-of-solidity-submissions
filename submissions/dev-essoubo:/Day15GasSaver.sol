// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISafeDepositBox
 * @dev Interface définissant les fonctionnalités communes pour tous les types de coffres-forts
 */
interface ISafeDepositBox {
    /**
     * @dev Permet de déposer un secret dans le coffre
     * @param secret Le secret à stocker
     */
    function storeSecret(string calldata secret) external;
    
    /**
     * @dev Permet de récupérer le secret stocké
     * @return Le secret stocké
     */
    function retrieveSecret() external view returns (string memory);
    
    /**
     * @dev Transfère la propriété du coffre à une nouvelle adresse
     * @param newOwner L'adresse du nouveau propriétaire
     */
    function transferOwnership(address newOwner) external;
    
    /**
     * @dev Vérifie si l'adresse fournie est le propriétaire du coffre
     * @param addr L'adresse à vérifier
     * @return true si l'adresse est propriétaire, false sinon
     */
    function isOwner(address addr) external view returns (bool);
    
    /**
     * @dev Renvoie l'adresse du propriétaire actuel
     * @return L'adresse du propriétaire
     */
    function getOwner() external view returns (address);
    
    /**
     * @dev Renvoie le type du coffre-fort
     * @return Le type du coffre-fort sous forme de chaîne
     */
    function getBoxType() external pure returns (string memory);
}

/**
 * @title BaseDepositBox
 * @dev Contrat de base implémentant les fonctionnalités communes des coffres-forts
 */
abstract contract BaseDepositBox is ISafeDepositBox {
    address private _owner;
    string private _secret;
    
    /**
     * @dev Modificateur qui restreint l'accès au propriétaire uniquement
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Base: caller is not the owner");
        _;
    }
    
    /**
     * @dev Constructeur qui initialise le propriétaire du coffre
     */
    constructor() {
        _owner = msg.sender;
    }
    
    /**
     * @dev Implémentation de la fonction storeSecret de l'interface
     */
    function storeSecret(string calldata secret) external virtual onlyOwner {
        _secret = secret;
    }
    
    /**
     * @dev Implémentation de la fonction retrieveSecret de l'interface
     */
    function retrieveSecret() external view virtual onlyOwner returns (string memory) {
        return _secret;
    }
    
    /**
     * @dev Implémentation de la fonction transferOwnership de l'interface
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Base: new owner is the zero address");
        _owner = newOwner;
    }
    
    /**
     * @dev Implémentation de la fonction isOwner de l'interface
     */
    function isOwner(address addr) external view virtual returns (bool) {
        return addr == _owner;
    }
    
    /**
     * @dev Implémentation de la fonction getOwner de l'interface
     */
    function getOwner() external view virtual returns (address) {
        return _owner;
    }
}

/**
 * @title BasicDepositBox
 * @dev Coffre-fort de base avec les fonctionnalités standard
 */
contract BasicDepositBox is BaseDepositBox {
    /**
     * @dev Renvoie le type du coffre-fort
     */
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

/**
 * @title PremiumDepositBox
 * @dev Coffre-fort premium avec fonctionnalités supplémentaires
 */
contract PremiumDepositBox is BaseDepositBox {
    uint256 private _creationTime;
    
    /**
     * @dev Constructeur qui enregistre le timestamp de création
     */
    constructor() {
        _creationTime = block.timestamp;
    }
    
    /**
     * @dev Renvoie le type du coffre-fort
     */
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }
    
    /**
     * @dev Fonction supplémentaire spécifique aux coffres premium
     * @return Le temps écoulé depuis la création du coffre
     */
    function getBoxAge() external view returns (uint256) {
        return block.timestamp - _creationTime;
    }
}

/**
 * @title TimeLockedDepositBox
 * @dev Coffre-fort avec verrouillage temporel
 */
contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private _unlockTime;
    
    /**
     * @dev Constructeur qui définit le délai de verrouillage
     * @param lockDuration Durée en secondes pendant laquelle le coffre sera verrouillé
     */
    constructor(uint256 lockDuration) {
        _unlockTime = block.timestamp + lockDuration;
    }
    
    /**
     * @dev Modificateur qui vérifie si la période de verrouillage est terminée
     */
    modifier unlockTimeReached() {
        require(block.timestamp >= _unlockTime, "TimeLocked: box is still locked");
        _;
    }
    
    /**
     * @dev Redéfinition de retrieveSecret pour ajouter la vérification de temps
     */
    function retrieveSecret() external view override unlockTimeReached returns (string memory) {
        return super.retrieveSecret();
    }
    
    /**
     * @dev Renvoie le type du coffre-fort
     */
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }
    
    /**
     * @dev Fonction supplémentaire pour connaître le temps restant avant déverrouillage
     * @return Le temps restant en secondes, 0 si déjà déverrouillé
     */
    function timeUntilUnlock() external view returns (uint256) {
        if (block.timestamp >= _unlockTime) {
            return 0;
        }
        return _unlockTime - block.timestamp;
    }
}

/**
 * @title VaultManager
 * @dev Contrat central qui gère tous les coffres-forts
 */
contract VaultManager {
    address private _owner;
    mapping(address => address[]) private _userBoxes;
    
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxTransferred(address indexed previousOwner, address indexed newOwner, address indexed boxAddress);
    
    /**
     * @dev Modificateur qui restreint l'accès au propriétaire uniquement
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "VaultManager: caller is not the owner");
        _;
    }
    
    /**
     * @dev Constructeur qui initialise le propriétaire du VaultManager
     */
    constructor() {
        _owner = msg.sender;
    }
    
    /**
     * @dev Crée un nouveau coffre-fort basique pour l'utilisateur
     * @return L'adresse du nouveau coffre-fort
     */
    function createBasicBox() external returns (address) {
        BasicDepositBox newBox = new BasicDepositBox();
        newBox.transferOwnership(msg.sender);
        _userBoxes[msg.sender].push(address(newBox));
        
        emit BoxCreated(msg.sender, address(newBox), "Basic");
        return address(newBox);
    }
    
    /**
     * @dev Crée un nouveau coffre-fort premium pour l'utilisateur
     * @return L'adresse du nouveau coffre-fort
     */
    function createPremiumBox() external returns (address) {
        PremiumDepositBox newBox = new PremiumDepositBox();
        newBox.transferOwnership(msg.sender);
        _userBoxes[msg.sender].push(address(newBox));
        
        emit BoxCreated(msg.sender, address(newBox), "Premium");
        return address(newBox);
    }
    
    /**
     * @dev Crée un nouveau coffre-fort avec verrouillage temporel pour l'utilisateur
     * @param lockDuration Durée en secondes pendant laquelle le coffre sera verrouillé
     * @return L'adresse du nouveau coffre-fort
     */
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(lockDuration);
        newBox.transferOwnership(msg.sender);
        _userBoxes[msg.sender].push(address(newBox));
        
        emit BoxCreated(msg.sender, address(newBox), "TimeLocked");
        return address(newBox);
    }
    
    /**
     * @dev Transfère un coffre-fort à un nouveau propriétaire
     * @param boxAddress L'adresse du coffre-fort à transférer
     * @param newOwner L'adresse du nouveau propriétaire
     */
    function transferBox(address boxAddress, address newOwner) external {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.isOwner(msg.sender), "VaultManager: caller is not the box owner");
        
        // Mise à jour des mappings
        address currentOwner = box.getOwner();
        
        // Suppression du coffre de la liste de l'ancien propriétaire
        address[] storage userBoxList = _userBoxes[currentOwner];
        for (uint i = 0; i < userBoxList.length; i++) {
            if (userBoxList[i] == boxAddress) {
                // Remplacement avec le dernier élément et suppression du dernier
                userBoxList[i] = userBoxList[userBoxList.length - 1];
                userBoxList.pop();
                break;
            }
        }
        
        // Transfert de propriété
        box.transferOwnership(newOwner);
        
        // Ajout du coffre à la liste du nouveau propriétaire
        _userBoxes[newOwner].push(boxAddress);
        
        emit BoxTransferred(currentOwner, newOwner, boxAddress);
    }
    
    /**
     * @dev Récupère la liste des coffres-forts d'un utilisateur
     * @param user L'adresse de l'utilisateur
     * @return Un tableau des adresses des coffres-forts
     */
    function getUserBoxes(address user) external view returns (address[] memory) {
        return _userBoxes[user];
    }
    
    /**
     * @dev Récupère des informations détaillées sur un coffre-fort
     * @param boxAddress L'adresse du coffre-fort
     * @return boxType Le type du coffre-fort
     * @return owner Le propriétaire du coffre-fort
     */
    function getBoxInfo(address boxAddress) external view returns (string memory boxType, address owner) {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        boxType = box.getBoxType();
        owner = box.getOwner();
    }
}