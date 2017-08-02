# Gilgamesh Token Smart Contract


Install `testrpc` Ethereum RPC client for testing and development
```sh
npm install -g ethereumjs-testrpc
```

Run EthereumJS TestRPC
```sh
testrpc
```

Testing smart contract
```
npm install
truffle init
truffle compile
truffle migrate --reset
truffle console
ContractName.at("0x5dfce3ed56e211120c26d2274674bf631f649a5b").balance.call()
```
