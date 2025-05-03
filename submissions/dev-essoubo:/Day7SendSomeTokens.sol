// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendSomeTokens {
    // Nom et symbole du token
    string public name = "SimpleToken";
    string public symbol = "STK";
    uint8 public decimals = 18;
    
    // Offre totale de tokens
    uint public totalSupply;
    
    // Mapping des soldes de token par adresse
    mapping(address => uint) public balanceOf;
    
    // Mapping des allocations (autorisations de dépense)
    mapping(address => mapping(address => uint)) public allowance;
    
    // Événements
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mint(address indexed to, uint value);
    event Burn(address indexed from, uint value);
    
    // Constructeur: créer une offre initiale de tokens
    constructor(uint _initialSupply) {
        totalSupply = _initialSupply * 10**uint(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // Fonction de transfert de tokens
    function transfer(address _to, uint _value) public returns (bool success) {
        // Validation des paramètres
        require(_to != address(0), "Destinataire invalide: adresse nulle");
        require(balanceOf[msg.sender] >= _value, "Solde insuffisant");
        
        // Effectuer le transfert
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        // Émettre l'événement de transfert
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    // Approuver un tiers à dépenser des tokens en votre nom
    function approve(address _spender, uint _value) public returns (bool success) {
        require(_spender != address(0), "Adresse du delegue invalide");
        
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    // Fonction de transfert de tokens depuis une autre adresse (si autorisé)
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        // Validation des paramètres
        require(_from != address(0), "Adresse source invalide");
        require(_to != address(0), "Adresse destinataire invalide");
        require(balanceOf[_from] >= _value, "Solde insuffisant");
        require(allowance[_from][msg.sender] >= _value, "Allocation insuffisante");
        
        // Effectuer le transfert
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        // Mettre à jour l'allocation
        allowance[_from][msg.sender] -= _value;
        
        // Émettre l'événement de transfert
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // Fonction de création de nouveaux tokens (réservée au propriétaire)
    function mint(address _to, uint _value) public returns (bool success) {
        require(_to != address(0), "Adresse destinataire invalide");
        
        balanceOf[_to] += _value;
        totalSupply += _value;
        
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        
        return true;
    }
    
    // Fonction pour brûler des tokens
    function burn(uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Solde insuffisant pour bruler");
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        
        return true;
    }
    
    // Fonction pour vérifier le solde d'une adresse
    function getBalance(address _owner) public view returns (uint) {
        return balanceOf[_owner];
    }
    
    // Fonction pour effectuer un transfert en masse (pour économiser du gaz)
    function batchTransfer(address[] memory _recipients, uint[] memory _values) public returns (bool success) {
        require(_recipients.length == _values.length, "Les tableaux de destinataires et de valeurs doivent avoir la meme taille");
        
        uint totalAmount = 0;
        
        // Calculer le montant total à transférer
        for (uint i = 0; i < _values.length; i++) {
            totalAmount += _values[i];
        }
        
        // Vérifier que l'expéditeur a suffisamment de tokens
        require(balanceOf[msg.sender] >= totalAmount, "Solde insuffisant pour le transfert par lots");
        
        // Effectuer les transferts
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Adresse destinataire invalide");
            
            balanceOf[msg.sender] -= _values[i];
            balanceOf[_recipients[i]] += _values[i];
            
            emit Transfer(msg.sender, _recipients[i], _values[i]);
        }
        
        return true;
    }
    
    // Fonction pour augmenter l'allocation d'un délégué
    function increaseAllowance(address _spender, uint _addedValue) public returns (bool success) {
        require(_spender != address(0), "Adresse du delegue invalide");
        
        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        
        return true;
    }
    
    // Fonction pour diminuer l'allocation d'un délégué
    function decreaseAllowance(address _spender, uint _subtractedValue) public returns (bool success) {
        require(_spender != address(0), "Adresse du delegue invalide");
        require(allowance[msg.sender][_spender] >= _subtractedValue, "Reduction d'allocation superieure a l'allocation actuelle");
        
        allowance[msg.sender][_spender] -= _subtractedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        
        return true;
    }
    
    // Fonction pour recevoir ETH (si quelqu'un envoie par erreur)
    receive() external payable {
        // Ne rien faire, juste accepter l'ETH
    }
    
    // Fonction pour retirer l'ETH envoyé par erreur (pour le propriétaire initial)
    function withdrawEther() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}