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