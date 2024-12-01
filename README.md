## Stablecoin and StablecoinSkeleton Smart Contract Project

**Overview**

Foundry consists of:

The Stablecoin and StablecoinSkeleton Smart Contract Project is a decentralized application that implements a stablecoin system using the Ethereum blockchain. The project consists of two main components:

Stablecoin: A burnable and mintable ERC20 token contract with strict ownership controls.

StablecoinSkeleton: A collateral-backed stablecoin management system that enforces health factor checks and integrates Chainlink price feeds to ensure proper valuation of collateral in USD.

## Project Structure

The project is organized into the following components:

Stablecoin.sol: Implements the Stablecoin contract that allows minting and burning by the owner.

StablecoinSkeleton.sol: Manages collateral deposits, stablecoin minting, and health factor checks.

Libraries and Interfaces: Includes imported contracts for Chainlink price feeds, reentrancy guards, and ERC20 interfaces.

## Setup Instructions

### Install Dependencies

Ensure you have the following installed:

Foundry: A fast, portable, and modular toolkit for Ethereum application development.

### Clone the Repository


```shell
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_PROJECT_FOLDER>
```

### Environment Setup

Set up the environment variables for network configurations and API keys (if required). Ensure you configure:

Chainlink Price Feeds: For converting collateral amounts to USD values.

RPC URL: To interact with the Ethereum network.


### Usage
### Deploying the Contracts

Deploy Stablecoin:

```shell
forge script script/DeployStablecoin.s.sol --rpc-url <YOUR_RPC_URL> --broadcast
```


### Deploy StablecoinSkeleton:

```shell
forge script script/DeployStablecoinSkeleton.s.sol --rpc-url <YOUR_RPC_URL> --broadcast```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Using the Contracts, Deposit Collateral

```shell
orge script script/Interactions.s.sol:DepositCollateral --rpc-url <YOUR_RPC_URL> --broadcast
```

### Redeem Collateral

```shell
forge script script/Interactions.s.sol:DepositCollateral --rpc-url <YOUR_RPC_URL> --broadcast
```

### Liquidate Collateral

```shell
forge script script/Interactions.s.sol:LiquidateCollateral --rpc-url <YOUR_RPC_URL> --broadcast
```

### Project Details

### Stablecoin.sol

Purpose: Implements the ERC20 token with burn and mint functionality.

### Key Features:

Minting only allowed by the owner.

Custom errors for zero-address minting and insufficient balance burns.

StablecoinSkeleton.sol

Purpose: Manages collateral deposits, stablecoin minting, and enforces health factor thresholds.

### Key Features:

Chainlink price feed integration for collateral valuation.

Custom errors for invalid operations such as zero deposits or unauthorized tokens.

Health factor calculations to prevent over-leveraging.

### License

This project is licensed under the MIT License.
