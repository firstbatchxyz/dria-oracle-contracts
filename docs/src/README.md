# LLM Oracle

This document provides instructions for LLM contracts using Foundry.

## Test

Compile the contracts:

```sh
make build
```

Run tests on local:

```sh
make test
```

## Format

Format code with:

```sh
make fmt
```

## Update

Update modules with:

```sh
make update
```

## Coverage

Check coverages with:

```sh
bash coverage.sh
```
or to see summarized coverages on terminal:

```sh
make cov
```

You can see coverages under the coverage directory.

## Storage Layout

Get storage layout with:

```sh
bash storage.sh
```

You can see storage layouts under the storage directory.

## Deployment

**Step 1.**
Import your `PUBLIC_KEY` and `ETHERSCAN_API_KEY` to env file.

> [!NOTE]
>
> Foundry expects the API key to be defined as `ETHERSCAN_API_KEY` even though you're using another explorer.

**Step 2.**
Create keystores for deployment. [See more for keystores](https://eips.ethereum.org/EIPS/eip-2335)

```sh
make local-key
```

or for Base Sepolia

```sh
make base-sepolia-key
```

> [!NOTE]
>
> Recommended to create keystores on directly on your shell.
> You HAVE to type your password on the terminal to be able to use your keys. (e.g when deploying a contract)

**Step 3.**
Enter your private key (associated with the public key you added to env file) and password on terminal. You'll see your public key on terminal.

> [!NOTE]
>
> If you want to deploy contracts on localhost please provide localhost public key for the command above.

**Step 4.** Required only for local deployment.

Start a local node with:

```sh
make anvil
```

**Step 5.**
Deploy the contracts on localhost (forked Base Sepolia by default) using Deploy script:

```sh
make deploy
```

or Base Sepolia with the command below:

```sh
make deploy base-sepolia
```

You can see deployed contract addresses under the `deployment/<chainid>.json`

## Gas Snapshot

Take the gas snapshot with:

```sh
make snapshot
```

You can see the snapshot `.gas-snapshot` file in the current directory.

## Format

Format code with:

```sh
make fmt
```

## Generate documentation

```sh
make doc
```

You can see the documentation under the `docs/` directory.
