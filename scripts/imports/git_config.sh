#!/bin/bash

# =============================
# Git config
# =============================

git_config(){
    # Prompt for user name
    read -p "Enter your Git user name: " username

    # Prompt for user email
    read -p "Enter your Git user email: " useremail

    # Set Git config globally
    git config --global user.name "$username"
    git config --global user.email "$useremail"

    # Confirmation
    echo "Git global config updated:"
    git config --global user.name
    git config --global user.email

    git config --global credential.helper store
    echo "git credential storing enabled"
}
