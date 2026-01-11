#!/bin/sh

#  ci_post_clone.sh
#  PayKey
#
#  Created by Agent on 2025/01/10.
#

# Checks if the build should proceed based on changed files.
# If only unrelated files (e.g., backend, docs) are changed, cancel the build.

echo "🔍 Checking for relevant changes..."

# Define the relevant paths (relative to the repo root)
# Note: Xcode Cloud clones the repo into a subdirectory, but we usually start at root or check properly.
# We are looking for changes in 'mobile/ios', 'mobile/lib', 'mobile/pubspec.*'

# If this is a PR, we can compare against the target branch.
# If not, we might check the last commit.

# For simplicity, we'll check the diff of the current HEAD against the previous commit or base.
# In Xcode Cloud, typically we are in a detached HEAD state or on a specific commit.

# Function to check changes
check_changes() {
    # git diff --name-only HEAD^ HEAD  <- This checks only the last commit.
    # Ideally we want to check the range of the PR, but that's harder to determine dynamically without env vars.
    # Xcode Cloud sets CI_PULL_REQUEST_TARGET_BRANCH for PRs.
    
    local changed_files
    
    if [ -n "$CI_PULL_REQUEST_TARGET_BRANCH" ]; then
        echo "Build triggered by PR targeting $CI_PULL_REQUEST_TARGET_BRANCH"
        # Fetch the target branch to compare
        git fetch origin "$CI_PULL_REQUEST_TARGET_BRANCH" --depth=1
        changed_files=$(git diff --name-only "origin/$CI_PULL_REQUEST_TARGET_BRANCH")
    else
        echo "Build triggered by push or manual action. Checking last commit."
        changed_files=$(git diff --name-only HEAD^ HEAD)
    fi

    echo "📂 Changed files:"
    echo "$changed_files"

    # Check if any changed file matches our criteria
    # We look for 'mobile/ios', 'mobile/lib', or 'mobile/pubspec'
    
    if echo "$changed_files" | grep -qE "^mobile/ios/|^mobile/lib/|^mobile/pubspec"; then
        echo "✅ Relevant files changed. Proceeding with build."
        return 0
    else
        echo "🛑 No relevant mobile changes found."
        echo "Skipping build to save resources."
        
        # There is no official "skip" command, but we can exit with success (0) and stop, 
        # or fail (1) to indicate "failure".
        # However, to stop Xcode Cloud from continuing to 'build', usually we have to fail or just exit.
        # But failing marks it as red. 
        # A common workaround is to throw an error message that we intend to stop.
        # Or simply let it run but maybe fail fast?
        # Actually, Apple Docs say custom scripts can't 'cancel' a workflow gracefully yet.
        # BUT, we can make the script fail, which stops the build. 
        # It will show as 'Build Failed', which is annoying but effective.
        
        # ALTERNATIVE: Just exit 0 and let it build? No, user wants to stop it.
        # Let's fail with a clear message.
        
        echo "❌ CANCELING BUILD: No changes in mobile directory."
        exit 1
    fi
}

check_changes
