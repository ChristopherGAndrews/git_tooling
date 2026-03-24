#!/bin/bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
SCRIPT_PATH=$( cd "$(dirname "$0")" && pwd )  # absolutized and normalized
SCRIPT_PATH_NAME="${SCRIPT_PATH}/${SCRIPT_NAME}"
SCRIPT_PID=$$

HELP_MESSAGE="
${SCRIPT_NAME} Clones and configures a git repo for ssh key signing in an environment where you have multiple Github identities configured in your ssh config file. It will scan your ssh config file for Github hosts and ask you to pick one to use for authentication when cloning the repo. It will then set the signing key for the repo to the identity file associated with the ssh host you picked.

-h              - Print help
-r <repo>       - The github repo to clone via ssh (e.g., git@github.com:<org>/<repo>.git)

Assumptions:

- You have multiple Github identities configured in your ssh config file with Host entries that include 'github.com' and IdentityFile entries that point to the private key files for each identity.

Example ssh config file:

Host personal.github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal

Host work.github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work

- You have your name and email added to the comment field of the public key file in the format #Name|email (e.g., #John Doe|john.doe@example.com)

Example public key file with comment:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCt... e #John Doe|john.doe@example.com

Usage:

./${SCRIPT_NAME} -r <repo>

"

# Get the arguments
while getopts hr: OPTIONS
do
  case "${OPTIONS}"
  in
  h) printf "${HELP_MESSAGE}" ; exit 0 ;;
  r) GITHUB_REPO="${OPTARG}" ;;
  esac
done

echo -------------------------------------------
# scan the ssh config file for github hosts and get the identity file for each
SSH_CONFIG_HOSTS=$(grep -iE "host\s+.*github.com" ~/.ssh/config | awk '{print $2}')

# print the list to the screen adding a number to each line
i=1
for SSH_HOST in ${SSH_CONFIG_HOSTS}; do
    echo "${i}) ${SSH_HOST}"
    i=$((i+1))
done
echo -------------------------------------------
# ask to pick a number
read -p "Pick a number to use for git authentication: " SSH_HOST_NUMBER

# get the ssh host from the list
SSH_HOST_PATH=$(echo "${SSH_CONFIG_HOSTS}" | sed -n "${SSH_HOST_NUMBER}p" | tr -d '[:space:]')

echo -------------------------------------------
echo "You picked ${SSH_HOST_PATH} for git authentication"

# get the identity file for the ssh host using ssh -G
SSH_IDENTITY_FILE=$(ssh -G "${SSH_HOST_PATH}" | grep -iE "identityfile\s+.*" | awk '{print $2}' | tr -d '[:space:]')

# safe expansion file path
SSH_IDENTITY_FILE=$(eval echo "$SSH_IDENTITY_FILE")

# print the identity file to the screen
printf "The identity file for ${SSH_HOST_PATH} is ${SSH_IDENTITY_FILE}\n"

echo -------------------------------------------

# if the repo is not set, ask for it
if [ -z "${GITHUB_REPO:-}" ]; then
# ask what github repo to clonegit@github.com:BC-Collab/aws-ses.git
read -p "Enter the github repo to clone via ssh (e.g., git@github.com:<org>/<repo>.git): " GITHUB_REPO
fi

# change the ssh url to use the ssh host path instead of github.com
GITHUB_REPO_SSH=$(echo ${GITHUB_REPO} | sed "s/github.com/${SSH_HOST_PATH}/g" | tr -d '[:space:]')
echo "Cloning ${GITHUB_REPO_SSH} using ${SSH_HOST_PATH} for authentication"
git clone "${GITHUB_REPO_SSH}"

# set the signing key for the repo to the identity file
GIT_DIR=$(basename "${GITHUB_REPO}" .git)
cd "${GIT_DIR}"
SIGNING_KEY_VALUE=$(cat ${SSH_IDENTITY_FILE})
git config --local user.signingkey "${SIGNING_KEY_VALUE}"

# if the signing key value has a comment with a #, split the comment Name|email
if [[ "${SIGNING_KEY_VALUE}" == *"#"* ]]; then
    SIGNING_KEY_COMMENT=$(echo "${SIGNING_KEY_VALUE}" | grep -oE "#.*" | sed "s/#//")
    SIGNING_KEY_NAME=$(echo "${SIGNING_KEY_COMMENT}" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    SIGNING_KEY_EMAIL=$(echo "${SIGNING_KEY_COMMENT}" | cut -d'|' -f2 | tr -d '[:space:]')
    git config --local user.name "${SIGNING_KEY_NAME}"
    git config --local user.email "${SIGNING_KEY_EMAIL}"
fi

echo -------------------------------------------
echo "Set the signing key for ${GIT_DIR} to the identity file ${SSH_IDENTITY_FILE}"

# print public key for the identity file
echo -------------------------------------------
echo "The public key for ${SSH_IDENTITY_FILE} is:"
cat ${SSH_IDENTITY_FILE}
echo ""

# print the git signing key for the repo
echo -------------------------------------------
echo "The git signing key settings for ${GIT_DIR} are:"
echo "User Name: $(git config --get user.name)"
echo "User Email: $(git config --get user.email)"
echo "Signing Key: $(git config --get user.signingkey)"
