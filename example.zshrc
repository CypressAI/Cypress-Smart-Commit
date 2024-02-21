# git
alias sc='smart_commit' #see below for function

# zsh
alias reload="source ~/.zshrc"

smart_commit() {
    # Temporary file to store the git diff
    diff_content=$(mktemp)

    # Capture the git diff output
    git diff > "$diff_content"

    # This prepares the diff content to be sent as part of a JSON payload
    escaped_diff=$(awk '{printf "%s\\n", $0}' "$diff_content" | sed 's/"/\\"/g')

    # Define system_prompt and user_prompt as per your script
    system_prompt="You're a talented engineer known for your skill at writing flawless git commit messages. When given a git diff write a perfect commit message, this should be concise, and descriptive. Please don't use any newlines. The commit message should be more than 20 words."
    user_prompt="Write a short git commit message based on the following changes, please add a single gitmoji at the start of the commit message. Don't explain the Gitmojis just use them. Don't include any numbering. If there isn't enough information to determine what was done just state 'minor changes' and list state the location, git diff: $escaped_diff"

    # Construct the JSON payload
    json_payload=$(jq -n \
                    --arg sp "$system_prompt" \
                    --arg up "$user_prompt" \
                    '{model_id: "mixtral-8x7b-32768", system_prompt: $sp, user_prompt: $up}')

    # Sending the request and capturing the output
    response=$(curl -s -H "Authorization: Bearer your_bearer_token_here" \
        -H "Content-Type: application/json" \
        --data "$json_payload" https://api.groq.com/v1/request_manager/text_completion)

    # Concatenate the response, preserving explicit newlines within content, and avoiding additional newlines
    concatenated_response=$(echo "$response" | jq -r '.result.content // empty' | tr -d '\n')

    # Prepare the git commit command using the concatenated response as the commit message
    git_commit_cmd="git add --all && git commit -m \"${concatenated_response}\""

    echo "The commit command has been prepared. Execute the following command to commit:"
    echo "$git_commit_cmd"
    # Depending on your system, adjust the clipboard command. For Linux, you might use `xclip` or `xsel`.
    # For macOS, `pbcopy` is correct. This example uses `pbcopy` for macOS users.
    # Linux users replace the following line with:
    # echo "$git_commit_cmd" | xclip -selection clipboard
    # or
    # echo "$git_commit_cmd" | xsel --clipboard --input
    echo "$git_commit_cmd" | pbcopy

    # Clean up
    rm "$diff_content"
}