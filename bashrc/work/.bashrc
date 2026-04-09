# Source sfaos bashrc
if [ -f /home/$USER/projects/auto/tools/bash/sfaos.sh ]; then
    source /home/$USER/projects/auto/tools/bash/sfaos.sh
fi

# Source PEM kit bashrc
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

# Only do this stuff if we're in an interactive shell
if [[ "$-" =~ 'i' ]]; then
    umask 022
fi

# Vault token — stored in a machine-local file, not tracked in dotfiles
# To set up: install -m 600 /dev/null ~/.vault_token_secret
#             echo 'export VAULT_TOKEN=<your-token>' > ~/.vault_token_secret
if [ -f "$HOME/.vault_token_secret" ]; then
    source "$HOME/.vault_token_secret"
fi
