# Eoracle Middleware

## Overview

eoracle extends the Ethereum Proof of Stake by providing a programmable data layer that connects smart contracts with real-world data.
This repository hosts the smart contracts necessary for creating Eoracle AVS contracts that interact with the EigenLayer core contracts.

EigenLayer is a set of smart contracts deployed on Ethereum that enable restaking of assets to secure new services called AVSs (actively validated services).

## Getting Started

To begin using the Eoracle Middleware, follow the instructions below. Additional documentation is provided to help you understand both Eoracle and EigenLayer.

### Documentation

#### Eoracle Overview
- General Information: [Eoracle Gitbook](https://eoracle.gitbook.io/eoracle)
- Operator Guide: [Eoracle Operator Guide](https://eoracle.gitbook.io/eoracle/eoracle-operator-guide)

#### EigenLayer Overview
- Introduction to EigenLayer: [You Could've Invented EigenLayer](https://www.blog.eigenlayer.xyz/ycie/)
- Restaking User Guide: [Restaking User Guide](https://docs.eigenlayer.xyz/restaking-guides/restaking-user-guide)
- Operator Guide: [EigenLayer Operator Guide](https://docs.eigenlayer.xyz/operator-guides/operator-introduction)

### Building and Running Tests

This repository utilizes Foundry for smart contract development. Follow the instructions in the [Foundry documentation](https://book.getfoundry.sh/) for installation and usage guidelines. Once Foundry is set up, you can build and test the project using the following commands:

```sh
foundryup
forge install
forge build
forge test
```

## Deployments

### Mainnet Deployment

| Name | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- |
| [`EOServiceManager`](https://github.com/Eoracle/eoracle-middleware/blob/main/src/EOServiceManager.sol) | [`0x23221c5bB90C7c57ecc1E75513e2E4257673F0ef`](https://etherscan.io/address/0x23221c5bB90C7c57ecc1E75513e2E4257673F0ef) | [`0xbE94...6F51`](https://etherscan.io/address/0xbE945dc0635214465b6a75B01AC46d6662636F51) | Proxy: [`TUP@4.7.1`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| [`EORegistryCoordinator`](https://github.com/Eoracle/eoracle-middleware/blob/main/src/EORegistryCoordinator.sol) | [`0x757E6f572AfD8E111bD913d35314B5472C051cA8`](https://etherscan.io/address/0x757E6f572AfD8E111bD913d35314B5472C051cA8) | [`0xe7a1...E9Ae`](https://etherscan.io/address/0xe7a11666e91b1a16cb8a560af5f58e35776fe9ae) | Proxy: [`TUP@4.7.1`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| [`EOStakeRegistry`](https://github.com/Eoracle/eoracle-middleware/blob/main/src/EOStakeRegistry.sol) | [`0x761DF0e99160a4bd19391475D2a1101eaab20F24`](https://etherscan.io/address/0x761DF0e99160a4bd19391475D2a1101eaab20F24) | [`0xD9Cc...72B4`](https://etherscan.io/address/0xd9cc5aa46e012a6e0b3006ef8ff9fe6e69f072b4) | Proxy: [`TUP@4.7.1`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| [`EOBLSApkRegistry`](https://github.com/Eoracle/eoracle-middleware/blob/main/src/EOBLSApkRegistry.sol) | [`0xBAdDb21a8fa8fbFDF81e967819B283787EbF84ec`](https://etherscan.io/address/0xBAdDb21a8fa8fbFDF81e967819B283787EbF84ec) | [`0xA41a...Fb7e`](https://etherscan.io/address/0xa41a4a572ac1c36b46d01998beb84460d8c7fb7e) | Proxy: [`TUP@4.7.1`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| [`EOIndexRegistry`](https://github.com/Eoracle/eoracle-middleware/blob/main/src/EOIndexRegistry.sol) | [`0x99617c9AE252d3924335507Fa17B94E5f2C3582B`](https://etherscan.io/address/0x99617c9AE252d3924335507Fa17B94E5f2C3582B) | [`0x89Bd...Ee34`](https://etherscan.io/address/0x89bd32161f918b30f619d7c8bc6086bdf812ee34) | Proxy: [`TUP@4.7.1`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
