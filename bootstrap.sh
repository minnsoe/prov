#!/bin/bash

set -euf -o pipefail
shopt -s expand_aliases

# terminal setup

bold=$(tput bold)
normal=$(tput sgr0)
alias echo="echo \"${bold}[ prov bootstrap ] ${normal}\""

# configuration

PROV="${HOME}/prov"
DOTFILES="${HOME}/dotfiles"

PROV_GIT_HTTPS="https://github.com/MinnSoe/prov.git"
PROV_GIT_SSH="git@github.com:MinnSoe/prov.git"
DOTFILES_GIT_HTTPS="https://github.com/MinnSoe/dotfiles.git"
DOTFILES_GIT_SSH="git@github.com:MinnSoe/dotfiles.git"

USER_PYTHON_BIN_DIR="$(python3 -c 'import site; print(site.USER_BASE)')/bin"
ANSIBLE_PLAYBOOK="${USER_PYTHON_BIN_DIR}/ansible-playbook"
ANSIBLE_GALAXY="${USER_PYTHON_BIN_DIR}/ansible-galaxy"

ensure_ansible_installed_for_user() {
  if [ -x ${ANSIBLE_PLAYBOOK} ]; then
    echo "User Ansible install present"
  else
    echo "Installing Ansible"
    yes | pip3 install -q --user --disable-pip-version-check ansible || [[ $? -eq 141 ]]
  fi
}

ensure_prov_playbook_okay() {
  if [ -f "${PROV}/playbook.yml" ]; then
    echo "Playbook repository present"
  else
    echo "Cloning prov playbooks"
    git clone ${PROV_GIT_HTTPS} ${PROV}
  fi

  pushd . > /dev/null
  cd ${PROV}
  if [ "$(git remote get-url origin)" != "${PROV_GIT_SSH}" ]; then
    echo "Setting prov git repository origin to SSH remote"
    git remote set-url origin ${PROV_GIT_SSH}
  fi
  popd > /dev/null
}

ensure_dotfiles_repo_okay() {
  if [ -d "${DOTFILES}" ]; then
    echo "Dotfiles repository present"
  else
    echo "Cloning dotfiles"
    git clone ${DOTFILES_GIT_HTTPS} ${DOTFILES}
  fi

  pushd . > /dev/null
  cd ${DOTFILES}
  if [ "$(git remote get-url origin)" != "${DOTFILES_GIT_SSH}" ]; then
    echo "Setting dotfiles git repository origin to SSH remote"
    git remote set-url origin ${DOTFILES_GIT_SSH}
  fi
  popd > /dev/null
}

ensure_galaxy_requirements_installed() {
  ${ANSIBLE_GALAXY} collection install -r ${PROV}/requirements.yml
}

print_bootstrap_info() {
  cat <<EOF

---
${bold}Bootstrap Info

${bold}Ansible Path:${normal}	${ANSIBLE_PLAYBOOK}
${bold}Playbook Path:${normal}	${PROV} 
${bold}Dotfiles Path:${normal}	${DOTFILES} 
---

System ready, run playbook with the following command:
${ANSIBLE_PLAYBOOK} ${PROV}/playbook.yml -K 


$(tput smul)Flag reference:$(tput rmul)
-K	Ask for priviledge escalation password (e.g. sudo)
--tags	Only run plays and tasks tagged with these values (inverse: --skip-tags)
--step	Iteractively execute tasks

EOF
}


main() {
  clear
  ensure_ansible_installed_for_user
  ensure_prov_playbook_okay
  ensure_dotfiles_repo_okay
  ensure_galaxy_requirements_installed
  print_bootstrap_info
}

main
