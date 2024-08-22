#!/bin/sh

# Default mode value
mode="prod"
deploy_frontend=true
force_frontend=false

# Define color codes
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to show script usage
show_usage() {
  echo "Usage: $0 [--mode=dev|prod] [--no-frontend] [--force-frontend]"
  exit 1
}

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    --mode=*)
      mode="${1#*=}"
      ;;
    --no-frontend)
      deploy_frontend=false
      ;;
    --force-frontend)
      force_frontend=true
      ;;
    *)
      show_usage
      ;;
  esac
  shift
done

# Validate the selected mode
if [ "$mode" != "dev" ] && [ "$mode" != "prod" ]; then
  echo "Error: Invalid mode selected. Valid options are 'dev' or 'prod'."
  show_usage
fi

# Warning for conflicting flags in development mode
if [ "$mode" = "dev" ] && [ "$deploy_frontend" = false ] && [ "$force_frontend" = true ]; then
  echo "${YELLOW}${BOLD}WARNING: --force-frontend will be ignored because --no-frontend is present.${NC}"
  force_frontend=false
fi

# Generate declaration files
echo "Generating declaration files..."

dfx generate account-manager
dfx generate workspace-orchestrator
dfx generate workspace-iam

# Add specific code for each mode here
if [ "$mode" = "dev" ]; then
  echo "Deploying in development environment..."
  dfx deploy internet-identity --network local
  dfx deploy account-manager --network local
	dfx deploy workspace-orchestrator --network local
  if [ "$deploy_frontend" = true ]; then
    if [ "$force_frontend" = true ]; then
      echo "Building frontend..."
      cd frontend
      npm run build
      cd ..
    fi
    dfx deploy frontend --network local
  fi
else
  echo "Deploying in production environment..."
	# TODO: Implement production deployment
  # dfx deploy account-manager --network ic
	# dfx deploy workspace-orchestrator --network ic
  # if [ "$force_frontend" = true ]; then
  #   echo "Building frontend..."
  #   cd frontend
  #   npm run build
  #   cd ..
  # fi
  # dfx deploy frontend --network ic
fi
