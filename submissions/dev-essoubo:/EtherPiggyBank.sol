// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    // Structure pour suivre les détails d'un déposant
    struct Depositor {
        uint totalDeposited; // montant total déposé
        uint lastDepositTime; // horodatage du dernier dépôt
        uint withdrawalCount; // nombre de retraits effectués
    }
    
    // Mapping pour suivre les soldes et les informations des déposants
    mapping(address => uint) public balances;
    mapping(address => Depositor) public depositorInfo;
    
    // Variables pour suivre les statistiques de la tirelire
    uint public totalDeposits;
    uint public totalWithdrawals;
    uint public totalUsers;
    address public topDepositor;
    uint public highestDeposit;
    
    // Événements pour notifier les actions sur la tirelire
    event Deposit(address indexed user, uint amount, uint timestamp);
    event Withdrawal(address indexed user, uint amount, uint timestamp);
    event NewTopDepositor(address indexed user, uint totalAmount);
    
    // Modifier pour vérifier si un utilisateur a des fonds
    modifier hasFunds() {
        require(balances[msg.sender] > 0, "Vous n'avez pas de fonds dans cette tirelire");
        _;
    }
    
    // Fonction de dépôt
    function deposit() public payable {
        require(msg.value > 0, "Le montant du depot doit etre superieur a zero");
        
        // Si c'est le premier dépôt de cet utilisateur, incrémenter le compteur d'utilisateurs
        if (balances[msg.sender] == 0 && depositorInfo[msg.sender].totalDeposited == 0) {
            totalUsers++;
        }
        
        // Mettre à jour le solde et les informations du déposant
        balances[msg.sender] += msg.value;
        depositorInfo[msg.sender].totalDeposited += msg.value;
        depositorInfo[msg.sender].lastDepositTime = block.timestamp;
        
        // Mettre à jour les statistiques globales
        totalDeposits += msg.value;
        
        // Vérifier si c'est le meilleur déposant
        if (depositorInfo[msg.sender].totalDeposited > highestDeposit) {
            highestDeposit = depositorInfo[msg.sender].totalDeposited;
            topDepositor = msg.sender;
            emit NewTopDepositor(msg.sender, highestDeposit);
        }
        
        // Émettre l'événement de dépôt
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    // Fonction pour recevoir de l'Ether directement (fonction de fallback)
    receive() external payable {
        deposit();
    }
    
    // Fonction de retrait
    function withdraw(uint _amount) public hasFunds {
        require(_amount > 0, "Le montant du retrait doit etre superieur a zero");
        require(_amount <= balances[msg.sender], "Montant de retrait superieur a votre solde");
        
        // Mettre à jour le solde et les informations du déposant
        balances[msg.sender] -= _amount;
        depositorInfo[msg.sender].withdrawalCount++;
        
        // Mettre à jour les statistiques globales
        totalWithdrawals += _amount;
        
        // Transférer l'Ether à l'utilisateur
        payable(msg.sender).transfer(_amount);
        
        // Émettre l'événement de retrait
        emit Withdrawal(msg.sender, _amount, block.timestamp);
    }
    
    // Fonction pour retirer tout le solde
    function withdrawAll() public hasFunds {
        uint amount = balances[msg.sender];
        withdraw(amount);
    }
    
    // Fonction pour obtenir le solde de l'utilisateur courant
    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }
    
    // Fonction pour obtenir les informations complètes du déposant
    function getMyInfo() public view returns (uint balance, uint totalDeposited, uint lastDepositTime, uint withdrawalCount) {
        return (
            balances[msg.sender],
            depositorInfo[msg.sender].totalDeposited,
            depositorInfo[msg.sender].lastDepositTime,
            depositorInfo[msg.sender].withdrawalCount
        );
    }
    
    // Fonction pour obtenir le solde total de la tirelire
    function getTotalBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    // Fonction pour vérifier si l'utilisateur est le meilleur déposant
    function isTopDepositor() public view returns (bool) {
        return msg.sender == topDepositor;
    }
    
    // Fonction pour obtenir le temps écoulé depuis le dernier dépôt
    function getTimeSinceLastDeposit() public view returns (uint) {
        uint lastDeposit = depositorInfo[msg.sender].lastDepositTime;
        if (lastDeposit == 0) return 0; // Aucun dépôt encore effectué
        return block.timestamp - lastDeposit;
    }
}