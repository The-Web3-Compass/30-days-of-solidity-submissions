# Injective Trading Bot

Un bot de trading automatisé pour l'échange décentralisé Injective Protocol. Ce contrat intelligent permet d'exécuter des ordres de trading automatisés sur le testnet Injective.

## Fonctionnalités

- 🚀 Déploiement de contrats sur le testnet Injective
- 💰 Dépôt et retrait de fonds
- 📈 Passer des ordres de trading spot
- 🔒 Gestion sécurisée des sous-comptes
- ⚡ Intégration avec les précompilations Injective

## Prérequis

- [Node.js](https://nodejs.org/) (version 16 ou supérieure)
- [Yarn](https://yarnpkg.com/) ou npm
- Un portefeuille Ethereum avec des fonds sur le testnet Injective

## Installation

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/Sopiloo/30-days-of-solidity-submissions.git
   cd 30-days-of-solidity-submissions
   ```

2. Installer les dépendances :
   ```bash
   npm install
   ```

3. Configurer l'environnement :
   ```bash
   cp .env.example .env
   ```
   Puis éditez le fichier `.env` avec vos clés d'API et votre clé privée.

## Configuration

Créez un fichier `.env` à la racine du projet avec les variables suivantes :

```
PRIVATE_KEY=VOTRE_CLE_PRIVEE_AVEC_0x
INJ_TESTNET_RPC_URL=https://testnet.sentry.tm.injective.network:443
```

## Déploiement

1. Déployer le contrat sur le testnet Injective :
   ```bash
   npx hardhat run scripts/deploy.js --network injective_testnet
   ```

2. Noter l'adresse du contrat déployé et la mettre à jour dans `.env` :
   ```
   CONTRACT_ADDRESS=0x...
   ```

## Utilisation

### 1. Approvisionner le contrat
```bash
node scripts/fund.js
```

### 2. Déposer des fonds sur l'échange
```bash
node scripts/deposit.js
```

### 3. Passer un ordre
```bash
node scripts/place-order.js
```

### 4. Annuler un ordre
```bash
node scripts/cancel-order.js
```

## Structure du projet

- `/contracts` - Contrats Solidity
  - `SimpleTradingBot.sol` - Contrat principal du bot de trading
  - `Exchange.sol` - Interface avec l'échange Injective
  - `ExchangeTypes.sol` - Types de données pour l'échange
  - `CosmosTypes.sol` - Types de données Cosmos

- `/scripts` - Scripts de déploiement et d'interaction
  - `deploy.js` - Déploie le contrat
  - `fund.js` - Approvisionne le contrat en fonds
  - `deposit.js` - Dépose des fonds sur l'échange
  - `place-order.js` - Passe un ordre de trading
  - `cancel-order.js` - Annule un ordre existant

## Sécurité

⚠️ **Important** : Ne partagez jamais votre clé privée ou votre fichier `.env`. Ce projet est conçu pour fonctionner sur le testnet uniquement.

## Licence

Ce projet est sous licence MIT.

## Auteur

[Sopiloo](https://github.com/Sopiloo)
