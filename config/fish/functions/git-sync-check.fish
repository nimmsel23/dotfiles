function git-sync-check --description "Pretty git sync status with gum"
    # Main header
    gum style \
        --border double \
        --border-foreground 212 \
        --padding "0 4" \
        --margin "1" \
        --align center \
        --bold \
        "GIT SYNC STATUS CHECK"

    echo ""

    # Run git-sync-enforcer and parse output
    set -l repos (git-sync-enforcer status 2>&1 | grep -E "^(dotfiles|AlphaOs-Vault|FADARO|agent-system):")

    # Create table data
    set -l table_data "REPO STATUS CHANGES UNPUSHED"

    for repo_line in $repos
        # Parse repo line
        set -l repo (echo $repo_line | awk '{print $1}' | tr -d ':')

        if string match -q "*Clean*" $repo_line
            set table_data "$table_data\n$repo ✅_Clean 0 0"
        else if string match -q "*CRITICAL*" $repo_line
            set -l changes (echo $repo_line | grep -oP '\d+(?= changes)' || echo "0")
            set -l unpushed (echo $repo_line | grep -oP '\d+(?= unpushed)' || echo "0")
            set table_data "$table_data\n$repo ❌_CRITICAL $changes $unpushed"
        else if string match -q "*⚠*" $repo_line
            set -l changes (echo $repo_line | grep -oP '\d+(?= changes)' || echo "0")
            set -l unpushed (echo $repo_line | grep -oP '\d+(?= unpushed)' || echo "0")
            set table_data "$table_data\n$repo ⚠️_Dirty $changes $unpushed"
        end
    end

    # Display as gum table
    echo -e $table_data | gum table --border rounded --border-foreground 117

    echo ""

    # Quick tips box
    gum style \
        --border rounded \
        --border-foreground 226 \
        --padding "1 2" \
        --margin "0 2" \
        "💡 Quick commands:
  repos          Interactive menu
  gse status     Raw status
  gse verify     Check remotes
  gse enforce    Sync all repos
  gsafe          Safe push with check"

    echo ""
end
