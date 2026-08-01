# Link only Gemini authentication. The container keeps its own settings,
# projects, history, extensions, and other state.
mkdir -p "$HOME/.gemini"

if [ -f "/mnt/host-gemini-oauth-creds.json" ]; then
    ln -sfn /mnt/host-gemini-oauth-creds.json "$HOME/.gemini/oauth_creds.json"
fi

if [ -f "/mnt/host-gemini-google-accounts.json" ]; then
    ln -sfn /mnt/host-gemini-google-accounts.json "$HOME/.gemini/google_accounts.json"
fi

if [ -L "$HOME/.gemini/oauth_creds.json" ]; then
    echo "Linked Gemini credentials; container settings and context remain isolated"
fi
