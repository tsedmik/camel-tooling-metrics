#!/bin/bash

# ==============================================================================
# GitHub Repository Data Retriever Script
#
# This script reads a list of GitHub repositories from a 'repositories.txt' file,
# queries the GitHub API for the number of open issues and pull requests, and
# appends this data to a separate CSV file for each repository.
#
# The CSV format is:
# Current date;Number of Open issues;Number of Open PRs
#
# ==============================================================================

# --- Prerequisites Check ---

# Check if 'jq' is installed. 'jq' is a lightweight and flexible command-line
# JSON processor, which is essential for parsing the API responses.
if ! command -v jq &> /dev/null
then
    echo "Error: 'jq' is not installed."
    echo "Please install it to run this script. For example, on Ubuntu/Debian:"
    echo "sudo apt-get install jq"
    echo "On macOS with Homebrew:"
    echo "brew install jq"
    exit 1
fi

# Check if 'repositories.txt' file exists
if [ ! -f "repositories.txt" ]; then
    echo "Error: The 'repositories.txt' file was not found."
    echo "Please create this file and add one 'REPOSITORY_OWNER/REPOSITORY_NAME' per line."
    exit 1
fi

# --- Configuration ---

# To avoid hitting GitHub's API rate limits, it's highly recommended to
# use a Personal Access Token (PAT).
# You can generate a PAT here: https://github.com/settings/tokens
# The PAT needs 'repo' or 'public_repo' scope.
# If you don't use a token, the script will use unauthenticated requests
# which have a lower rate limit (60 requests per hour).
#
# Replace 'YOUR_GITHUB_PAT' with your actual token.
# If you are not using a token, leave this variable blank.
USER_TOKEN="YOUR_GITHUB_PAT"

# --- Main Script Logic ---

echo "Starting data retrieval for GitHub repositories..."

# Loop through each line in the repositories.txt file.
# The `read -r` command ensures that backslashes are not interpreted.
while read -r repo_name || [[ -n "$repo_name" ]]; do
    # Skip empty lines.
    if [[ -z "$repo_name" ]]; then
        continue
    fi

    echo "Processing repository: $repo_name"

    # --- API Calls ---

    # Construct the base URL for the API calls.
    # The `per_page=1` parameter is a trick to get the `total_count` from
    # the search API without fetching all the results, making the request faster.
    issues_url="https://api.github.com/search/issues?q=repo:$repo_name+is:issue+is:open&per_page=1"
    pr_url="https://api.github.com/search/issues?q=repo:$repo_name+is:pr+is:open&per_page=1"

    # Set up the authentication header if a token is provided.
    # if [ ! -z "$USER_TOKEN" ]; then
    #    AUTH_HEADER="-H \"Authorization: token $USER_TOKEN\""
    # else
    #    AUTH_HEADER=""
    # fi

    # Make the curl call for issues and store the JSON output.
    # The `-s` flag silences the progress meter.
    issues_json=$(eval "curl -s $AUTH_HEADER \"$issues_url\"")

    # Use 'jq' to extract the 'total_count' field from the JSON.
    issues_count=$(echo "$issues_json" | jq '.total_count')

    # Make the curl call for pull requests and store the JSON output.
    pr_json=$(eval "curl -s $AUTH_HEADER \"$pr_url\"")

    # Use 'jq' to extract the 'total_count' field from the JSON.
    pr_count=$(echo "$pr_json" | jq '.total_count')

    # Handle potential API errors. If the counts are null or not a number,
    # it indicates an issue with the API response.
    if [ -z "$issues_count" ] || [ -z "$pr_count" ] || [ "$issues_count" == "null" ] || [ "$pr_count" == "null" ]; then
        echo "Warning: Could not retrieve data for '$repo_name'. Skipping."
        echo "Check the repository name or if you've hit the API rate limit."
        continue
    fi

    # --- Data Formatting and Storage ---

    # Get the current date in 'YYYY-MM-DD' format.
    current_date=$(date '+%Y-%m-%d')

    # Create the CSV filename by replacing slashes with hyphens.
    # For example, 'owner/repo' becomes 'owner-repo.csv'.
    csv_filename=./out/$(echo "$repo_name" | sed 's/\//-/g').csv

    # If the CSV file doesn't exist, create it and add the header row.
    if [ ! -f "$csv_filename" ]; then
        echo "Date;Open Issues;Open PRs" > "$csv_filename"
    fi

    # Append the new data line to the CSV file.
    # The `>>` operator appends to the file.
    echo "$current_date;$issues_count;$pr_count" >> "$csv_filename"
    echo "  -> Data appended to $csv_filename"

done < repositories.txt

echo "Script finished. Data has been saved to the respective CSV files."