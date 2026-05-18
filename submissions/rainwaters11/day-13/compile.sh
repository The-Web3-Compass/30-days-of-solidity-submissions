#!/usr/bin/env bash
script_dir="$(cd "$(dirname "$0")" && pwd)"
npx --yes -p solc solcjs --bin --abi --output-dir "$script_dir/build" "$script_dir/WhitelistedTokenSale.sol" && echo "Compiled OK → $script_dir/build/"
