# This repository contains my daily submissions for the **30 Days of Solidity** challenge, organised by **The Web3 Compass**.


## Documentation refined with the help of AI tools to improve clarity and consistency.


# Final Note

I have completed all 30 days of the Solidity challenge.

Folders such as lib, out, cache, and broadcast have been removed or excluded using .gitignore to avoid issues caused by large dependency trees that previously corrupted Git history. (Some earlier files will have lib)

## Key Technical Issues Encountered: 

- Accidental addition of the lib directory, which contained over 100,000 files and caused Git corruption.

- Workspace confusion between multiple local repositories, leading to missing or untracked folders (particularly Day 20).

- Push rejections due to remote updates, requiring rebase and cleanup.

- Merge-path conflicts caused by incorrect directory structures.

- Early misconfigurations in the Foundry project layout before standardizing the repo.

All issues have now been resolved.

## Verification:  

- The structure of every day's submission has been reviewed, and all tasks compile and run successfully in both Foundry and Remix.

# End of the Challenge.

## Injective Tasks (Day 9 & Day 25)

The Injective tasks introduced precompile-based development, which differs from standard EVM execution. Both Day 9 (Injective Bank Module) and Day 25 (CLOB Module) required calling Injective’s native precompile addresses. These precompiles cannot run inside a normal local EVM, so the tests were designed only to confirm contract deployment, event triggers, and function structure. Foundry setup required adding forge-std, correcting remappings, and ensuring a clean folder structure without the lib directory. All Injective submissions compile successfully and follow the same Foundry structure used throughout the challenge.
