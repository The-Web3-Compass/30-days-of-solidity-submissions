#!/bin/bash

cast \
  wallet import injTestAcc \
  --interactive

forge \
  create src/BguizToken.sol:BguizToken \
  --rpc-url injectiveEvm \
  --account injTestAcc \
  --value 1000000000000000000 \
  --legacy \
  --broadcast