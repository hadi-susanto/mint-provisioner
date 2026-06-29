alias gcm="git commit -m"
alias gp="git push"
alias gb="git branch"
alias gbr="git branch -r"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gbdr="git branch -dr"

# Push current branch to origin and set upstream
gpsup() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    git push -u origin "$branch"
}
