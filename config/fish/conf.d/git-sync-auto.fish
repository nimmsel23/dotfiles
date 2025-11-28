# Git Sync Auto-Check Configuration
# =================================
# Optional: Uncomment functions below to enable auto-checks

# --- Auto-check on terminal start (DISABLED by default) ---
# function __git_sync_startup_check --on-event fish_prompt
#     # Only run once per session
#     if not set -q __git_sync_checked
#         set -g __git_sync_checked 1
#
#         # Silent check, only warn if critical
#         set -l critical_repos (git-sync-enforcer status 2>/dev/null | grep -c "CRITICAL")
#
#         if test $critical_repos -gt 0
#             set_color red
#             echo "⚠️  WARNING: $critical_repos repos have critical uncommitted changes"
#             set_color normal
#             echo "   Run: repos (or gses) to check"
#             echo ""
#         end
#     end
# end

# --- Weekly reminder (DISABLED by default) ---
# function __git_sync_weekly_reminder --on-event fish_prompt
#     # Check if it's been >7 days since last check
#     set -l last_check_file ~/.cache/git-sync-last-check
#     set -l current_time (date +%s)
#
#     if test -f $last_check_file
#         set -l last_check (cat $last_check_file)
#         set -l days_since (math "($current_time - $last_check) / 86400")
#
#         if test $days_since -gt 7
#             set_color yellow
#             echo "💡 Reminder: Run 'repos' to check git sync status (last check: $days_since days ago)"
#             set_color normal
#             echo $current_time > $last_check_file
#         end
#     else
#         mkdir -p ~/.cache
#         echo $current_time > $last_check_file
#     end
# end

# --- Smart pre-push check (ACTIVE by default) ---
# This function enhances git push to check for uncommitted changes in OTHER repos
function __git_sync_pre_push_hint --on-event fish_preexec
    # Check if command is git push
    if string match -q "git push*" $argv
        # Quick silent check for dirty repos (excluding current)
        set -l current_repo (basename (git rev-parse --show-toplevel 2>/dev/null))

        # Only warn if there are OTHER dirty repos
        set -l other_dirty (git-sync-enforcer status 2>/dev/null | grep -c "⚠\|✗" | string trim)

        if test $other_dirty -gt 1
            set_color yellow
            echo "💡 Hint: Other repos have uncommitted changes. Run 'repos' to check."
            set_color normal
        end
    end
end

# To ENABLE auto-checks:
# 1. Uncomment the function you want above
# 2. Reload fish: exec fish
# 3. Or source this file: source ~/.config/fish/conf.d/git-sync-auto.fish
