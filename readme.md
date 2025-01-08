# Orderly Cross-Chain Service

A secure cross-chain messaging infrastructure enabling communication between Orderly Network's vaults on EVM chains and the central ledger. Built on LayerZero protocol.

## Overview

The service facilitates cross-chain operations between:
- Multiple vault deployments across EVM chains
- Central ledger on Orderly chain

### Core Components

1. **Cross-Chain Relay**: LayerZero protocol abstraction layer
2. **Vault Cross-Chain Manager**: Message handling for vault contracts
3. **Ledger Cross-Chain Manager**: Message handling for ledger contract

## Development

### Prerequisites

- Node.js (v20+) & Yarn
- Foundry (latest version)

### Installation

```bash
git submodule update --init
yarn install
forge install
```

### Configuration

Copy and configure environment variables:
```bash
cp .env.example .env
```

Required environment variables:
```shell
# Deployment Keys
DEV_PK=
QA_PK=
STAGING_PK=
PRODUCTION_PK=

# Network Configuration
XXX_RPC_URL=
XXX_CHAIN_ID=
XXX_LZ_CHAIN_ID=
XXX_ENDPOINT=

# Explorer Configuration
XXX_EXPLORER_API_URL=
XXX_EXPLORER_API_KEY=
XXX_EXPLORER_TYPE=
```
Replace `XXX` with network name (e.g., ETH, ARBITRUM)

### Build & Test

```bash
forge build
forge test
```

### Project Structure

```
├── contracts/           # Smart contracts
├── script/             # Deployment scripts
├── config/             # Configuration files
└── test/              # Test files
```

## License

[MIT License](LICENSE)
