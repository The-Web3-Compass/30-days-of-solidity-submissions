# 30 Days of Solidity Submissions

This repository is the official submission archive for the Web3 Compass `30 Days of Solidity` challenge.

Use it to submit your daily Solidity solutions by creating your own copy of the repository, adding your work under `submissions/`, and opening a pull request back to the official repo.



## Submission Flow

1. Create or sign in to your GitHub account.
2. Open the Web3 Compass GitHub page and find the `30-days-of-solidity-submissions` repository.
3. Click `Fork` to create a copy of this repository under your own GitHub account.
4. Clone your fork to your local machine.
5. Add your challenge solution inside the `submissions/` folder.
6. Commit and push your changes to your fork.
7. Open a pull request from your fork to the official Web3 Compass repository.
8. Share your pull request link in the Telegram group or official submission form if required.

## Step-by-Step Guide

### 1. Fork the Repository

Forking creates your own copy of this repository in your GitHub account.

- Open the official repository on GitHub
- Click `Fork`
- Make sure the fork is created under your own account

### 2. Clone Your Fork

Copy the URL of your fork and run:

```bash
git clone <your-fork-url>
cd 30-days-of-solidity-submissions
```

This downloads the repository to your machine so you can add your files locally.

### 3. Add Your Solutions

Inside `submissions/`, create a folder using your name or GitHub username.

Example:

```text
submissions/
└── your-name/
```

You can organize your submissions in either of these ways:

### Option A: Add Solidity files directly

```text
submissions/
└── your-name/
    ├── Day1-ClickCounter.sol
    ├── Day2-SaveMyName.sol
    └── Day3-PollStation.sol
```

### Option B: Create day-wise folders

```text
submissions/
└── your-name/
    └── day1/
        └── ClickCounter.sol
```

Both are acceptable as long as your files are clearly organized inside your own folder under `submissions/`.

If you are writing code in Remix, copy your Solidity code from Remix and paste it into files in this repository using the same structure.

### 4. Commit and Push Your Changes

After adding your solution files, run:

```bash
git add .
git commit -m "Add Day 1 solution"
git push
```

This uploads your changes from your local machine to your GitHub fork.

### 5. Open a Pull Request

Once your changes are pushed:

1. Open your fork on GitHub.
2. Click `Contribute`.
3. Click `Open pull request`.
4. Confirm that the base repository is the official Web3 Compass repository.
5. Confirm that the compare branch is your fork with your new submission.
6. Add a title and description if needed.
7. Click `Create pull request`.

Your pull request will then be reviewed by the team. If everything looks correct, it will be merged into the official repository.

### 6. Submit the Pull Request Link

After creating the pull request:

- Open the PR page
- Copy the pull request URL
- Share that link in the Telegram group or official submission form if requested

## Recommended Folder Structure

```text
submissions/
└── your-github-username/
    ├── Day1-ClickCounter.sol
    ├── Day2-SaveMyName.sol
    ├── Day3-PollStation.sol
    └── day14/
        ├── IDepositBox.sol
        ├── BaseDepositBox.sol
        ├── BasicDepositBox.sol
        ├── PremiumDepositBox.sol
        ├── TimeLockedDepositBox.sol
        └── VaultManager.sol
```

## Important Notes

- Add your work only inside your own folder under `submissions/`.
- Do not remove or overwrite other participants' files.
- Keep filenames clear so reviewers can identify the challenge day easily.
- Multi-file submissions are fine for advanced days.
- This repository is mainly a submission archive, so structure may vary between contributors.

## Quick Commands

```bash
git clone <your-fork-url>
cd 30-days-of-solidity-submissions
git add .
git commit -m "Add Day X solution"
git push
```

## Summary

The workflow is simple:

1. Fork the repository.
2. Clone your fork.
3. Add your solution under `submissions/your-name/`.
4. Commit and push.
5. Open a pull request to the official repository.
6. Share the pull request link.
