    
    // Statistiques
    uint public totalTipsWei;
    uint public totalTipsCount;
    address public topTipper;
    uint public topTipAmount;// SPDX-License-Identifier: MIT
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
    uint public weiPerXOF = 8 * 10**11; // 0.0008 ETH par 1000 XOF (exemple)
    uint public weiPerGBP = 7 * 10**14; // 0.0007 ETH par GBP (exemple)
    uint public weiPerCAD = 4 * 10**14; // 0.0004 ETH par CAD (exemple)
    
    // Tableau contenant tous les pourboires
    Tip[] public tips;
    
    // Mapping des contributions totales par adresse
    mapping(address => uint) public totalTipsByAddress;
    
    // Mapping des contributions totales par devise
    mapping(string => uint) public totalTipsByCurrency;
    
    // Mapping des devises supportées
    mapping(string => bool) public supportedCurrencies;
    string[] public currencyList;
    
    // Mapping pour les pourboires favoris par utilisateur
    mapping(address => string) public favoriteCurrency;
    
    // Mapping des objectifs de pourboires (goals)
    mapping(string => uint) public tipGoals; // devise => objectif
    
    // Paliers de récompenses pour les donateurs fréquents
    uint public bronzeThreshold = 1 * 10**16; // 0.01 ETH
    uint public silverThreshold = 5 * 10**16; // 0.05 ETH
    uint public goldThreshold = 1 * 10**17;   // 0.1 ETH
    
    // Événements
    event TipReceived(address indexed tipper, uint amountWei, string currency, uint currencyAmount, string message);
    event FundsWithdrawn(address indexed owner, uint amount);
    event RateUpdated(string currency, uint newRate);
    event GoalSet(string currency, uint amount);
    event GoalReached(string currency, uint amount);
    event CurrencyAdded(string currency);
    event BadgeEarned(address indexed tipper, string badge);
    
    // Modificateur pour restreindre certaines fonctions au propriétaire uniquement
    modifier onlyOwner() {
        require(msg.sender == owner, "Seul le proprietaire peut effectuer cette action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Initialiser les devises supportées
        _addCurrency("ETH");
        _addCurrency("USD");
        _addCurrency("EUR");
        _addCurrency("JPY");
        _addCurrency("XOF");
        _addCurrency("GBP");
        _addCurrency("CAD");
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
    
    // Fonction pour les pourboires en XOF (Franc CFA)
    function tipInXOF(uint _amountXOF, string memory _message) public payable {
        require(_amountXOF > 0, "Le montant en XOF doit etre superieur a zero");
        
        // Calculer le montant équivalent en wei
        uint amountWei = _amountXOF * weiPerXOF;
        
        // Vérifier que le montant envoyé est correct
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en XOF specifie");
        
        // Enregistrer le pourboire
        _recordTip(msg.sender, amountWei, "XOF", _amountXOF, _message);
        
        // Rembourser l'excédent si nécessaire
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction pour les pourboires en GBP
    function tipInGBP(uint _amountGBP, string memory _message) public payable {
        require(_amountGBP > 0, "Le montant en GBP doit etre superieur a zero");
        
        uint amountWei = _amountGBP * weiPerGBP;
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en GBP specifie");
        
        _recordTip(msg.sender, amountWei, "GBP", _amountGBP, _message);
        
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction pour les pourboires en CAD
    function tipInCAD(uint _amountCAD, string memory _message) public payable {
        require(_amountCAD > 0, "Le montant en CAD doit etre superieur a zero");
        
        uint amountWei = _amountCAD * weiPerCAD;
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant pour le montant en CAD specifie");
        
        _recordTip(msg.sender, amountWei, "CAD", _amountCAD, _message);
        
        uint excessAmount = msg.value - amountWei;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }
    
    // Fonction universelle pour envoyer un pourboire dans n'importe quelle devise supportée
    function tipInCurrency(string memory _currency, uint _amount, string memory _message) public payable {
        require(supportedCurrencies[_currency], "Devise non supportee");
        require(_amount > 0, "Le montant doit etre superieur a zero");
        
        uint amountWei = convertToEth(_currency, _amount);
        require(msg.value >= amountWei, "Le montant d'ETH envoye est insuffisant");
        
        _recordTip(msg.sender, amountWei, _currency, _amount, _message);
        
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
        
        // Vérifier les badges/récompenses
        _checkBadges(_tipper);
        
        // Vérifier si un objectif a été atteint
        _checkGoals(_currency);
        
        // Émettre l'événement
        emit TipReceived(_tipper, _amountWei, _currency, _currencyAmount, _message);
    }
    
    // Fonction pour vérifier et attribuer des badges
    function _checkBadges(address _tipper) internal {
        uint totalContribution = totalTipsByAddress[_tipper];
        
        if (totalContribution >= goldThreshold) {
            emit BadgeEarned(_tipper, "Gold Supporter");
        } else if (totalContribution >= silverThreshold) {
            emit BadgeEarned(_tipper, "Silver Supporter");
        } else if (totalContribution >= bronzeThreshold) {
            emit BadgeEarned(_tipper, "Bronze Supporter");
        }
    }
    
    // Fonction pour vérifier si les objectifs sont atteints
    function _checkGoals(string memory _currency) internal {
        uint currentTotal = totalTipsByCurrency[_currency];
        uint goal = tipGoals[_currency];
        
        if (goal > 0 && currentTotal >= goal) {
            emit GoalReached(_currency, goal);
        }
    }
    
    // Fonction interne pour ajouter une devise supportée
    function _addCurrency(string memory _currency) internal {
        if (!supportedCurrencies[_currency]) {
            supportedCurrencies[_currency] = true;
            currencyList.push(_currency);
            emit CurrencyAdded(_currency);
        }
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
    
    function updateXOFRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerXOF = _newRate;
        emit RateUpdated("XOF", _newRate);
    }
    
    function updateGBPRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerGBP = _newRate;
        emit RateUpdated("GBP", _newRate);
    }
    
    function updateCADRate(uint _newRate) public onlyOwner {
        require(_newRate > 0, "Le taux doit etre superieur a zero");
        weiPerCAD = _newRate;
        emit RateUpdated("CAD", _newRate);
    }
    
    // Fonction pour définir un objectif de pourboires
    function setTipGoal(string memory _currency, uint _amount) public onlyOwner {
        require(supportedCurrencies[_currency], "Devise non supportee");
        require(_amount > 0, "L'objectif doit etre superieur a zero");
        
        tipGoals[_currency] = _amount;
        emit GoalSet(_currency, _amount);
    }
    
    // Fonction pour définir la devise favorite d'un utilisateur
    function setFavoriteCurrency(string memory _currency) public {
        require(supportedCurrencies[_currency], "Devise non supportee");
        favoriteCurrency[msg.sender] = _currency;
    }
    
    // Ajouter une nouvelle devise (réservé au propriétaire)
    function addCurrency(string memory _currency) public onlyOwner {
        _addCurrency(_currency);
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
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("XOF"))) {
            return _amountWei / weiPerXOF;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("GBP"))) {
            return _amountWei / weiPerGBP;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("CAD"))) {
            return _amountWei / weiPerCAD;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("ETH"))) {
            return _amountWei;
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
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("XOF"))) {
            return _amount * weiPerXOF;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("GBP"))) {
            return _amount * weiPerGBP;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("CAD"))) {
            return _amount * weiPerCAD;
        } else if (keccak256(bytes(_currency)) == keccak256(bytes("ETH"))) {
            return _amount;
        } else {
            revert("Devise non supportee");
        }
    }
    
    // Obtenir le badge d'un utilisateur
    function getUserBadge(address _user) public view returns (string memory) {
        uint totalContribution = totalTipsByAddress[_user];
        
        if (totalContribution >= goldThreshold) {
            return "Gold Supporter";
        } else if (totalContribution >= silverThreshold) {
            return "Silver Supporter";
        } else if (totalContribution >= bronzeThreshold) {
            return "Bronze Supporter";
        } else {
            return "New Supporter";
        }
    }
    
    // Obtenir le progrès vers un objectif
    function getGoalProgress(string memory _currency) public view returns (uint current, uint goal, uint percentage) {
        current = totalTipsByCurrency[_currency];
        goal = tipGoals[_currency];
        
        if (goal > 0) {
            percentage = (current * 100) / goal;
            if (percentage > 100) percentage = 100;
        } else {
            percentage = 0;
        }
        
        return (current, goal, percentage);
    }
    
    // Obtenir la liste des devises supportées
    function getSupportedCurrencies() public view returns (string[] memory) {
        return currencyList;
    }
    
    // Obtenir les statistiques d'un utilisateur
    function getUserStats(address _user) public view returns (
        uint totalContributed,
        uint tipCount,
        string memory badge,
        string memory favCurrency
    ) {
        // Compter le nombre de pourboires de cet utilisateur
        uint count = 0;
        for (uint i = 0; i < tips.length; i++) {
            if (tips[i].tipper == _user) {
                count++;
            }
        }
        
        return (
            totalTipsByAddress[_user],
            count,
            getUserBadge(_user),
            favoriteCurrency[_user]
        );
    }
    
    // Obtenir le solde actuel du contrat
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
