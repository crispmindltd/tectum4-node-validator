# Welcome to MAINNET Tectum Blockchain Node v4.0 Beta! #

## Description ##

Tectum Blockchain Node is a component of the Tectum blockchain designed to provide access to the functionality of the blockchain network. Anyone who downloads and runs this node becomes a full participant in the Tectum network and can take advantage of all its benefits.

The network node offers the following functionalities for participants:
1. Token management (in development).
2. Transaction processing.
3. User key management.
4. Becoming a validator.
5. Coin (TET) staking.
6. Viewing blockchain chains.

## Web Server ##
Tectum Blockchain Node includes a local web server that processes requests. It provides explorer functions, allowing users to view information about blocks and transactions, staking tokens, becoming a validator, performing transfers, and managing keys.

Settings for web serever in `settings.ini` section `[http]`:

```
[http]
enabled=true
port=8917
```


## Endpoints ##

Tectum Blockchain Node supports the following types of requests:

### Coin operations: ###

-   **[POST /coins/transfer](docs/coin_operations/POST_coins_transfer.md)**: To transfer TET between two addresses
-   **[GET /coins/transfer?id=N](docs/coin_operations/GET_coins_transfers.md)**: Retrieve full information of transfer for the TET
-   **[POST /coins/stake](docs/coin_operations/POST_coins_stake.md)**: Staking TET to become a network validator
-   **[POST /coins/migrate](docs/coin_operations/POST_coins_migrate.md)**: Migrate TET to new address
-   **[GET /coins/transfers](docs/coin_operations/GET_coins_transfers.md)**: Retrieve the transfer history for the TET
-   **[GET /coins/balance/byaddress](docs/coin_operations/GET_coins_balance_byAddress.md)**: Retrieve TET balance by address
-   **[GET /coins/transfers/user](docs/coin_operations/GET_coins_transfers_user.md)**: Retrieve the TET transfer history for a specific user

### Key management: ###

-   **[GET /keys/new](docs/key_management/GET_keys_generate.md)**: Generate a private/public key pair
-   **[POST /keys/recover](docs/key_management/POST_keys_recovery.md)**: Recover keys using a seed phrase

### Settings: ###

-   **[GET /version](docs/settings/GET_version_request.md)**: View node version

### Blocks: ###

-   **[GET /blockscount](docs/blocks/GET_blocks_count.md)**: Retrieve the total count of blocks in the blockchain


## Settings.ini ##

Settings for Mainnet:

```
[connections]
nodes=[arch1.open.tectum.io:50000,arch2.open.tectum.io:50000,arch3.open.tectum.io:50000,arch4.open.tectum.io:50000,arch5.open.tectum.io:50000,arch6.open.tectum.io:50000,arch7.open.tectum.io:50000,arch8.open.tectum.io:50000,arch9.open.tectum.io:50000,arch10.open.tectum.io:50000,arch11.open.tectum.io:50000,arch12.open.tectum.io:50000]
```

Settings for Testnet:

```
[connections]
nodes=[arch1.test.open.tectum.io:50000, arch2.test.open.tectum.io:50001,arch3.test.open.tectum.io:50002,arch4.test.open.tectum.io:50003,arch5.test.open.tectum.io:50004,arch6.test.open.tectum.io:50005]

```

Settings for Web server. Send request to 'http://localhost:8917' by using API

```
[http]
enabled=true
port=8917
```

Settings level logs. If you want view all logs you need set `logs_level=3`

```
[settings]
logs_level=3
```