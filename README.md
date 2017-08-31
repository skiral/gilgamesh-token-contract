# Gilgamesh Platform Smart contracts
<img src="https://www.gilgameshplatform.com/img/logo-gilgamesh-3d.svg" width ='500' />

Gilgamesh Platform is knowledge-sharing social platform powered by the Ethereum network through Smart Contracts.

Gilgamesh Token "GIL" is an ERC20 compliant token.

## Smart Contracts
 Token Contract:

 - [ERC20Token.sol](/contracts/ERC20Token.sol) - Standard ERC20 Token Interface.
 - [SecureERC20Token.sol](/contracts/SecureERC20Token.sol) - Secure ERC20 Token implementation with additional secure methods.
 - [GilgameshToken.sol](/contracts/GilgameshToken.sol) - Gilgamesh Token contract.

 Token Sale Contract:
 - [GilgameshTokenSale.sol](/contracts/GilgameshTokenSale.sol) - Gilgamesh Token Sale contract.

## Running smart contracts in Development

### Setting up environment

#### Install Node v8
```sh
nvm use 8
```

#### Install dependencies
```sh
npm install
```

#### Install `testrpc` Ethereum RPC client for testing and development
```sh
npm install -g ethereumjs-testrpc
```

#### Install truffle globally
```sh
npm install -g truffle
```

### Deployment and Testing

#### Run EthereumJS TestRPC
```sh
testrpc
```

#### Compile smart contracts
```sh
truffle compile
```

#### Deploy Smart contracts on TestRPC
```sh
truffle migrate --reset
```

#### Load truffle console
```sh
truffle console
```

## Development
All code is hand crafted with love by Skiral inc.
