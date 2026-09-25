if command -v bws >/dev/null 2>&1 && [ "$BWS_REINSTALL" != "true" ]; then
  exit 0
fi
curl https://bws.bitwarden.com/install | sh
