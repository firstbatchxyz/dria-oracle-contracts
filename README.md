<p align="center">
  <img src="https://raw.githubusercontent.com/firstbatchxyz/.github/refs/heads/master/branding/dria-logo-square.svg" alt="logo" width="168">
</p>

<p align="center">
  <h1 align="center">
    Dria Oracle Contracts
  </h1>
  <p align="center">
    <i>Fully on-chain LLMs.</i>
  </p>
</p>

<p align="center">
    <a href="https://opensource.org/licenses/Apache-2-0" target="_blank">
        <img alt="License: Apache 2.0" src="https://img.shields.io/badge/license-Apache_2.0-7CB9E8.svg">
    </a>
    <a href="./.github/workflows/test.yml" target="_blank">
        <img alt="Workflow: Tests" src="https://github.com/firstbatchxyz/dria-oracle-contracts/actions/workflows/test.yml/badge.svg?branch=master">
    </a>
    <a href="https://discord.gg/dria" target="_blank">
        <img alt="Discord" src="https://dcbadge.vercel.app/api/server/dria?style=flat">
    </a>
</p>

## Installation

First, make sure you have the requirements:

- We are using [Foundry](https://book.getfoundry.sh/), so make sure you [install](https://book.getfoundry.sh/getting-started/installation) it first.
- Upgradable contracts make use of [NodeJS](https://nodejs.org/en), so you should [install](https://nodejs.org/en/download/package-manager) that as well.

Clone the repository:

```sh
git clone git@github.com:firstbatchxyz/dria-oracle-contracts.git
```

Install dependencies with:

```sh
forge install
```

Compile the contracts with:

```sh
forge clean && forge build
```

### Upgradability

We are using [openzeppelin-foundry-upgrades](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades) library. To make sure upgrades are **safe**, you must do one of the following (as per their [docs](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades?tab=readme-ov-file#before-running)) before you run `forge script` or `forge test`:

- `forge clean` beforehand, e.g. `forge clean && forge test`
- include `--force` option when running, e.g. `forge test --force`

> [!NOTE]
>
> Note that for some users this may fail (see [issue](https://github.com/firstbatchxyz/dria-oracle-contracts/issues/16)) due to a missing NPM package called `@openzeppelin/upgrades-core`. To fix it, do:
>
> ```sh
> npm install @openzeppelin/upgrades-core@latest -g
> ```

### Updates

To update contracts to the latest library versions, use:

```sh
forge update
```

## Usage

### Setup

To be able to use our contracts, we need an RPC endpoint and a wallet.

### Create Wallet

We use keystores for wallet management, with the help of [`cast wallet`](https://book.getfoundry.sh/reference/cast/wallet-commands) command.

Use the command below to create your keystore. The command will prompt for your **private key**, and a **password** to encrypt the keystore itself.

```sh
cast wallet import <WALLET_NAME> --interactive
```

> [!ALERT]
>
> Note that you will need to enter the password when you use this keystore.

You can see your keystores under the default directory (`~/.foundry/keystores`) with the command:

```sh
cast wallet list
```

### Prepare RPC Endpoint

To interact with the blockchain, we require an RPC endpoint. You can get one from:

- [Alchemy](https://www.alchemy.com/)
- [Infura](https://www.infura.io/)
- [or see more here](https://www.alchemy.com/best/rpc-node-providers)

You will use this endpoint for the commands that interact with the blockchain, such as deploying and upgrading; or while doing fork tests.

### Deploy Contract

Deploy the contract with:

```sh
forge clean && forge script ./script/Deploy.s.sol:Deploy<CONTRACT_NAME> \
--rpc-url <RPC_URL> \
--account <WALLET_NAME> \
--broadcast
```

or for instant verification use:

```sh
forge clean && forge script ./script/Deploy.s.sol:Deploy<CONTRACT_NAME> \
--rpc-url <RPC_URL> \
--account <WALLET_NAME> \
--sender <ADDRESS> --broadcast \
--verify --verifier <etherscan|blockscout|sourcify> --verifier-url <VERIFIER_URL>
```

> [!NOTE] > `<VERIFIER_URL>` should be expolorer's homepage url. Forge reads your `<ETHERSCAN_API_KEY>` from .env file so you don't need to add this at the end of `<VERIFIER_URL>`.
>
> e.g.
> `https://base-sepolia.blockscout.com/api/` for `Base Sepolia Network`

You can see deployed contract addresses under the `deployment/<chainid>.json`

## Verify Contract

Verify contract manually with:

```sh
forge verify-contract <CONTRACT_ADDRESS> src/$<CONTRACT_NAME>.sol:<CONTRACT_NAME> --verifier <etherscan|blockscout|sourcify> --verifier-url <VERIFIER_URL>
```

## Testing & Diagnostics

Run tests on local network:

```sh
forge clean && forge test

# or -vvv to show reverts in detail
forge clean && forge test -vvv
```

or fork an existing chain and run the tests on it:

```sh
forge clean && forge test --rpc-url <RPC_URL>
```

### Coverage

Check coverages with:

```sh
forge clean && bash coverage.sh
```

or to see summarized coverages on terminal:

```sh
forge clean && forge coverage --no-match-coverage "(test|mock|script)"
```

You can see coverages under the coverage directory.

### Storage Layout

Get storage layout with:

```sh
forge clean && bash storage.sh
```

You can see storage layouts under the storage directory.

### Gas Snapshot

Take the gas snapshot with:

```sh
forge clean && forge snapshot
```

You can see the snapshot `.gas-snapshot` file in the current directory.

## Documentation

We have auto-generated documentation under the [`docs`](./docs) folder, generated with the following command:

```sh
forge doc
```

We provide an MDBook template over it, which you can open via:

```sh
cd docs && mdbook serve --open
```

## License

We are using Apache-2.0 license.
