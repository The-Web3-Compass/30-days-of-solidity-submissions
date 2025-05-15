// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    // Structure pour stocker les informations sur un pourboire
    struct Tip {
        address tipper;
        uint amountWei;
        string currency;
        uint currencyAmount;
        string message;
        uint timestamp;
    }

    // Adresse du propriétaire de la tirelire
    address public owner;
    
    // Taux de conversion (simplifiés) - valeurs fixes pour la démonstration
    // Ces valeurs représentent combien de wei équivaut à 1 unité de chaque devise
    // Dans un contrat réel, ces valeurs pourraient être mises à jour via un oracle
    uint public weiPerUSD = 5 * 10**14; // 0.0005 ETH par USD (exemple)
    uint public weiPerEUR = 6 * 10**14; // 0.0006 ETH par EUR (exemple)
    uint public weiPerJPY = 3 * 10**12; // 0.000003 ETH par JPY (exemple)
    
    // Tableau contenant tous les pourboires
    Tip[] public tips;
    
    // Mapping des contributions totales par adresse
    mapping(address => uint) public totalTipsByAddress;
    
    // Mapping des contributions totales par devise
    mapping(string => uint) public totalTipsByCurrency;
    
    // Statistiques
    uint public totalTipsWei;
    uint public totalTipsCount;
    address public topTipper;
    uint public topTipAmount;
    
    // Événements
    event TipReceived(address indexed tipper, uint amountWei, string currency, uint currencyAmount, string message);
    event FundsWithdrawn(address indexed owner, uint amount);
    event RateUpdated(string currency, uint newRate);
    
    // Modificateur pour restreindre certaines fonctions au propriétaire uniquement
    modifier onlyOwner() {
        require(msg.sender == owner, "Seul le proprietaire peut effectuer cette action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Fonction pour recevoir des pourboires en ETH directement
    function tipInEth(string memory _message) public payable {
        require(msg.value > 0, "Le pourboire doit etre superieur a zero");
        
        // Enregistrer le pourboire
        _recordTip(msg.sender, msg.value, "ETH", msg.value / 10**18, _message);
    }
    
    // Fonction pour les pourboires en USD (simulation)
    function tipInUSD(uint _amountUSD, string memory _message) public payable {
        require(_amountUSD > 0, "Le montant en USD doit etre superieur a zero");
        
        // Calculer le montant équivalent en wei
        uint amountWei = _amountUSD * weiPerUSD;
        
        // Vérifier que le montant envoyé est correct
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en USD specifie");
        
        // Enregistrer le pourboire
        _recordTip(msg.sender, amountWei, "USD", _amountUSD, _message);
        
        // Rembourser l'excédent si nécessaire
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction pour les pourboires en EUR (simulation)
    function tipInEUR(uint _amountEUR, string memory _message) public payable {
        require(_amountEUR > 0, "Le montant en EUR doit etre superieur a zero");
        
        // Calculer le montant équivalent en wei
        uint amountWei = _amountEUR * weiPerEUR;
        
        // Vérifier que le montant envoyé est correct
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en EUR specifie");
        
        // Enregistrer le pourboire
        _recordTip(msg.sender, amountWei, "EUR", _amountEUR, _message);
        
        // Rembourser l'excédent si nécessaire
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction pour les pourboires en JPY (simulation)
    function tipInJPY(uint _amountJPY, string memory _message) public payable {
        require(_amountJPY > 0, "Le montant en JPY doit etre superieur a zero");
        
        // Calculer le montant équivalent en wei
        uint amountWei = _amountJPY * weiPerJPY;
        
        // Vérifier que le montant envoyé est correct
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en JPY specifie");
        
        // Enregistrer le pourboire
        _recordTip(msg.sender, amountWei, "JPY", _amountJPY, _message);
        
        // Rembourser l'excédent si nécessaire
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction interne pour enregistrer un pourboire
    function _recordTip(address _tipper, uint _amountWei, string memory _currency, uint _currencyAmount, string memory _message) internal {
        // Créer un nouvel objet Tip
        Tip memory newTip = Tip({
            tipper: _tipper,
            amountWei: _amountWei,
            currency: _currency,
            currencyAmount: _currencyAmount,
            message: _message,
            timestamp: block.timestamp
        });
        
        // Ajouter le pourboire au tableau
        tips.push(newTip);
        
        // Mettre à jour les statistiques
        totalTipsByAddress[_tipper] += _amountWei;
        totalTipsByCurrency[_currency] += _currencyAmount;
        totalTipsWei += _amountWei;
        totalTipsCount++;
        
        // Mettre à jour le top tipper si nécessaire
        if (totalTipsByAddress[_tipper] > totalTipsByAddress[topTipper]) {
            topTipper = _tipper;
        }
        
        // Mettre à jour le montant du plus gros pourboire si nécessaire
        if (_amountWei > topTipAmount) {
            topTipAmount = _amountWei;
        }
        
        // Émettre l'événement
        emit TipReceived(_tipper, _amountWei, _currency, _currencyAmount, _message);
    }
    
    // Fonction fallback pour recevoir des ETH directement
    receive() external payable {
        // Enregistrer comme un pourboire en ETH sans message
        _recordTip(msg.sender, msg.value, "ETH", msg.value / 10**18, "");
    }
    
    // Permettre au propriétaire de retirer les fonds
    function withdraw(uint _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Montant superieur au solde disponible");
        
        payable(owner).transfer(_amount);
        emit FundsWithdrawn(owner, _amount);
    }
    
    // Permettre au propriétaire de retirer tous les fonds
    function withdrawAll() public onlyOwner {
        uint amount = address(this).balance;
        payable(owner).transfer(amount);
        emit FundsWithdrawn(owner, amount);
    }
    
    // Mettre à jour les taux de conversion (seul le propriétaire peut le faire)
    function updateUSDRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerUSD = _newRate;
        emit RateUpdated("USD", _newRate);
    }
    
    function updateEURRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerEUR = _newRate;
        emit RateUpdated("EUR", _newRate);
    }
    
    function updateJPYRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerJPY = _newRate;
        emit RateUpdated("JPY", _newRate);
    }
    
    // Fonctions pour obtenir des informations sur les pourboires
    function getTipsCount() public view returns (uint) {
        return tips.length;
    }
    
    function getTipDetails(uint _index) public view returns (
        address tipper,
        uint amountWei,
        string memory currency,
        uint currencyAmount,
        string memory message,
        uint timestamp
    ) {
        require(_index < tips.length, "Index hors limites");
        Tip memory tip = tips[_index];
        return (tip.tipper, tip.amountWei, tip.currency, tip.currencyAmount, tip.message, tip.timestamp);
    }
    
    // Obtenir les N derniers pourboires
    function getRecentTips(uint _count) public view returns (
        address[] memory tippers,
        uint[] memory amounts,
        string[] memory currencies,
        string[] memory messages
    ) {
        uint count = _count;
        if (count > tips.length) {
            count = tips.length;
        }
        
        tippers = new address[](count);
        amounts = new uint[](count);
        currencies = new string[](count);
        messages = new string[](count);
        
        for (uint i = 0; i < count; i++) {
            uint index = tips.length - 1 - i;
            tippers[i] = tips[index].tipper;
            amounts[i] = tips[index].amountWei;
            currencies[i] = tips[index].currency;
            messages[i] = tips[index].message;
        }
        
        return (tippers, amounts, currencies, messages);
    }
    
    // Convertir un montant en ETH vers une autre devise
    function convertEthTo(string memory _currency, uint _amountWei) public view returns (uint) {
        if (keccak256(bytes(_currency)) == keccak256(bytes("USD"))) {
            return _amountWei / weiPerUSD;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("EUR"))) {
            return _amountWei / weiPerEUR;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("JPY"))) {
            return _amountWei / weiPerJPY;
        } else {
            revert("Devise non supportee");
        }
    }
    
    // Convertir un montant depuis une autre devise vers ETH
    function convertToEth(string memory _currency, uint _amount) public view returns (uint) {
        if (keccak256(bytes(_currency)) == keccak256(bytes("USD"))) {
            return _amount * weiPerUSD;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("EUR"))) {
            return _amount * weiPerEUR;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("JPY"))) {
            return _amount * weiPerJPY;
        } else {
            revert("Devise non supportee");
        }
    }
    
    // Obtenir le solde actuel du contrat
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}