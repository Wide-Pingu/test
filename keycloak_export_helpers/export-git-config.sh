#!/bin/bash

gh auth logout 1>/dev/null 2>&1

gh auth login --with-token <<- EOF
$GITHUB_TOKEN
EOF

gh config set git_protocol https -h github.com
gh auth setup-git
gh repo clone padoa/keycloak-rights

