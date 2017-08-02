# Gilgamesh Token Smart Contract


Install `testrpc` Ethereum RPC client for testing and development
```sh
npm install -g ethereumjs-testrpc
```


Testing smart contract

Install dependencies
```sh
npm install
```

Install truffle globally
```sh
npm install -g truffle
```

Compile smart contracts
```sh
truffle compile
```

Run EthereumJS TestRPC
```sh
testrpc
```

Deploy Smart contracts on TestRPC
```sh
truffle migrate --reset
```

Load truffle console
```sh
truffle console
```

Access Smart contracts and web3 API
```sh
web3.eth.blockNumber //6
GilgameshToken.at("0xb03f2fd128dc31d04ad7bf2b594ad96f27bfefcf").admin()
```
