#!/bin/bash

SC_ADDRESS=${1}

forge verify-contract \
  --rpc-url injectiveEvm \
  --verifier blockscout \
  --verifier-url 'https://testnet.blockscout-api.injective.network/api/' \
  ${SC_ADDRESS} \
  src/BguizToken.sol:BguizToken+-