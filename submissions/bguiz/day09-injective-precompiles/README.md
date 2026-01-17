# Injective Bank module via precompile in ERC20 token

## Usage

Compile smart contracts.

```shell
forge build
```

Deploy to Injective Testnet.

```shell
script/deploy.sh

# copy the output from the deploy script containing the deployed address and save that in an env var
SC_ADDRESS=0x...
```

Verify to add ABI and source to network explorer.

```shell
script/verify.sh ${SC_ADDRESS}
```

Interact using queries and transactions.

```shell
script/query.sh ${SC_ADDRESS}
script/transact.sh ${SC_ADDRESS}
script/query.sh ${SC_ADDRESS}
```
