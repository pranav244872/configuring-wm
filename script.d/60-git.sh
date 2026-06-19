setup_git() {
  section "Git configuration"
  git config --global credential.credentialStore plaintext
  git-credential-manager configure

  read -rp "Enter your GitHub Email: " git_email
  read -rp "Enter your GitHub Username: " git_username

  git config --global user.email "$git_email"
  git config --global user.name "$git_username"

  echo
  ok "Email: $(git config --global user.email)"
  ok "Name:  $(git config --global user.name)"
}
