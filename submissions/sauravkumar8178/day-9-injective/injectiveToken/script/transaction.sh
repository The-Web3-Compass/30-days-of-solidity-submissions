#!/bin/bash

SC_ADDRESS=${1}

cast send \
  --legacy \
  --rpc-url injectiveEvm \
  --gas-price 160000000 \
  --gas-limit 2000000 \
  --account injTestAcc \
  ${SC_ADDRESS} \
  "transfer(address,uint256)(bool)" \
  0xb1Bd56C69cd62c0eA41FbF2CFc66Bfb1375c28eC \
  100