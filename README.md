# Welcome to TESTNET Tectum Blockchain Node v4.0.100 beta! #

## Description ##

Tectum Blockchain Node is a component of the Tectum blockchain designed to provide access to the functionality of the blockchain network. Anyone who downloads and runs this node becomes a full participant in the Tectum network and can take advantage of all its benefits.

The network node offers the following functionalities for participants:
1. Token management (in development).
2. Transaction processing.
3. User key management.
4. Becoming a validator.
5. Token staking.
6. Viewing blockchain chains.

## Web Server ##
Tectum Blockchain Node includes a local web server that processes requests. It provides explorer functions, allowing users to view information about blocks and transactions, as well as an interface for creating new tokens, staking tokens, becoming a validator, performing transfers, and managing keys.

## Endpoints ##

Tectum Blockchain Node supports the following types of requests:

### Token operations: ###

-   **[POST /tokens/transfer](docs/tokens_transfer_request.md)**: To transfer tokens between two addresses
-   **[POST /tokens/stake](docs/tokens_stake_request.md)**: Staking tokens to become a network validator

### Key management: ###

-   **[GET /keys/new](docs/keys_generate_request.md)**: Generate a private/public key pair
-   **[POST /keys/recover](docs/keys_recovery_request.md)**: Recover keys using a seed phrase

### Settings: ###

-   **[GET /version](docs/version_request.md)**: View node version