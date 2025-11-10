#!/bin/bash

SC_ADDRESS=${1}

cast call \
  --rpc-url injectiveEvm \
  ${SC_ADDRESS} \
  "totalSupply()(uint256)"

cast call \
  --rpc-url injectiveEvm \
  ${SC_ADDRESS} \
  "balanceOf(address)(uint256)" \
  0xb1Bd56C69cd62c0eA41FbF2CFc66Bfb1375c28eC