# Orderly Cross-Chain Service

A secure cross-chain messaging infrastructure enabling communication between Orderly Network's vaults on EVM chains and the central ledger. Built on LayerZero protocol.

## Orderly Cross-Chain Relay V2

The Orderly Cross-Chain [Relay V2](https://gitlab.com/orderlynetwork/orderly-v2/cc-v2/-/tree/dev?ref_type=heads) is an OApp based on LayerZero V2, and used to connect Vault chains (Arbitrum, OP, Base, Ethereum, etc.) to the Ledger chain (Orderly L2).

### Architecture

To migrate from the previous version, we need to:

1. Deploy the new CrossChainRelayV2 contract on both Ledger and Vault chains.
2. Upgrade the CCManager contracts on both Ledger and Vault chains.
3. Set Cross-Chain option on the CCManager contracts to enable the Relay V2.
4. Relay message through the new CrossChainRelayV2 contract.

The following diagram shows the architecture based on the new relay:

```
                         +---------+   LzV1    +---------+
                  +------+CCRelayV1+-----------+CCRelayV1+-----+
                  |      +---------+           +---------+     |
                  |                                            |
                  |                                            |
             +----+----+                                  +----+----+
+-------+    |  Vault  |                                  | Ledger  |     +--------+
| Vault +----+CCManager|                                  |CCManager+-----+ Ledger |
+-------+    +----+----+                                  +----+----+     +--------+
                  |                                            |
                  |                                            |
                  |      +---------+           +---------+     |
                  +------+CCRelayV2+-----------+CCRelayV2+-----+
                         +---------+   LzV2    +---------+
```

Note: To backward compatible for the inflight messages through the relay V1, we need to keep the CCManager contracts callable by both relay V1 and V2 for a while. Once the inflight messages are executed, we can disable the CCManager contracts callable by the relay V1.

### Set Configuration

TODO @Zion

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
