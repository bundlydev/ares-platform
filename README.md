# Fullstack dApp (Motoko + NextJS + Internet Identity)

This template is designed to easily build applications deployed on ICP using Motoko + Next.js + Internet Identity

## Table of Contents

- [Getting Started](#getting-started)
  - [In the Cloud](#in-the-cloud)
  - [Manual Setup](#manual-setup)

## Getting Started

### In the cloud

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/bundlydev/ares-platform/?quickstart=1)

Create a .env file:

```bash
cp frontend/.env-codespaces-example frontend/.env
```

Get environment values:

```bash
# Create all canisters
dfx canister create --all

# Get workspace-orchestrator canister id
dfx canister id workspace-orchestrator

# Get account-manager canister id
dfx canister id account-manager

# Get internet-identity canister id
dfx canister id internet-identity

# Get your Codespace name
echo $CODESPACE_NAME
```

Replace values in the `frontend/.env` file:

```bash
# Replace YOUR_CODESPACE_NAME with your Codespace name
NEXT_PUBLIC_IC_HOST_URL=https://YOUR_CODESPACE_NAME-4943.app.github.dev/
# Replace YOUR_ACCOUNT_MANAGER_CANISTER_ID with your account-manager canister id
NEXT_PUBLIC_ACCOUNT_MANAGER_CANISTER_ID=YOUR_ACCOUNT_MANAGER_CANISTER_ID
# Replace YOUR_WORKSPACE_ORCHESTRATOR_CANISTER_ID with your workspace-orchestrator canister id
NEXT_PUBLIC_WORKSPACE_ORCHESTRATOR_CANISTER_ID=YOUR_WORKSPACE_ORCHESTRATOR_CANISTER_ID
# Replace YOUR_INTERNET_IDENTITY_CANISTER_ID with your internet-identity canister id
NEXT_PUBLIC_INTERNET_IDENTITY_URL=https://YOUR_CODESPACE_NAME-4943.app.github.dev/?canisterId=YOUR_INTERNET_COMPUTER_CANISTER_ID
```

Generate did files:

```bash
dfx generate account-manager
dfx generate workspace-orchestrator
dfx generate workspace-iam
```

Deploy your canisters:

```bash
sh scripts/deploy.sh --mode=dev
```

You will receive a result similar to the following (ids could be different four you):

```bash
URLs:
  Frontend canister via browser
    frontend:
      - http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai
      - http://br5f7-7uaaa-aaaaa-qaaca-cai.localhost:4943/
    internet-identity:
      - http://127.0.0.1:4943/?canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai
      - http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/
  Backend canister via Candid interface:
    account-manager: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=be2us-64aaa-aaaaa-qaabq-cai
    internet-identity: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=bkyz2-fmaaa-aaaaa-qaaaq-cai
		workspace-orchestrator: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=br5f7-7uaaa-aaaaa-qaaca-cai
```

To interact with the frontend the url can be obtained as follows:

```bash
echo https://$CODESPACE_NAME-4943.app.github.dev/?canisterId=$(dfx canister id frontend)
```

### Manual Setup

Ensure the following are installed on your system:

- [Node.js](https://nodejs.org/en/) `>= 21`
- [DFX](https://internetcomputer.org/docs/current/developer-docs/build/install-upgrade-remove) `>= 0.20.1`
- [Mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/docs/install)

Clone the project

```bash
  git clone https://github.com/bundlydev/ares-platform.git
```

Go to the project directory

```bash
  cd ares-platform
```

Start a ICP local replica:

```bash
dfx start --background --clean
```

Install dependencies

```bash
npm install
mops install
```

Create a .env file:

```bash
cp frontend/.env-example frontend/.env
```

Get your canister ids:

```bash
# Create canisters
dfx canister create --all

# Get workspace-orchestrator canister id
dfx canister id workspace-orchestrator

# Get account-manager canister id
dfx canister id account-manager

# Get internet-identity canister id
dfx canister id internet-identity
```

Replace values in the .env file:

```bash
# Replace port if needed
NEXT_PUBLIC_IC_HOST_URL=http://localhost:4943
# Replace YOUR_ACCOUNT_MANAGER_CANISTER_ID with your account-manager canister id
NEXT_PUBLIC_ACCOUNT_MANAGER_CANISTER_ID=YOUR_ACCOUNT_MANAGER_CANISTER_ID
# Replace YOUR_WORKSPACE_ORCHESTRATOR_CANISTER_ID with your workspace-orchestrator canister id
NEXT_PUBLIC_WORKSPACE_ORCHESTRATOR_CANISTER_ID=YOUR_WORKSPACE_ORCHESTRATOR_CANISTER_ID
# Replace YOUR_INTERNET_IDENTITY_CANISTER_ID with your internet-identity canister id
NEXT_PUBLIC_INTERNET_IDENTITY_URL=http://YOUR_INTERNET_IDENTITY_CANISTER_ID.localhost:4943
```

Generate did files:

```bash
dfx generate account-manager
dfx generate workspace-orchestrator
dfx generate workspace-iam
```

Deploy your canisters:

```bash
sh scripts/deploy.sh --mode=dev
```

You will receive a result similar to the following (ids could be different four you):

```bash
URLs:
  Frontend canister via browser
    frontend:
      - http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai
      - http://br5f7-7uaaa-aaaaa-qaaca-cai.localhost:4943/
    internet-identity:
      - http://127.0.0.1:4943/?canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai
      - http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/
  Backend canister via Candid interface:
    account-manager: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=be2us-64aaa-aaaaa-qaabq-cai
    internet-identity: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=bkyz2-fmaaa-aaaaa-qaaaq-cai
		workspace-orchestrator: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=br5f7-7uaaa-aaaaa-qaaca-cai
```

Open your web browser and enter the Frontend URL to view the web application in action.

## Test frontend without deploy to ICP Replica

Comment the next line into `frontend/next.config.mjs` file:

```javascript
// output: "export",
```

Then, navitate to `frontend` folder:

`cd frontend`

Run the following script:

`npm run dev`
