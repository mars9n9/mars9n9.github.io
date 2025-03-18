#!/bin/bash

# Function to recursively generate the table of contents
generate_toc() {
    local base_folder="$1"
    local filetype_filter="$2"
    local level="$3"
    local toc=""
    local nl=$'\n' # Define newline character

    # List directories excluding specific patterns
    local repo_folder_structure

    local oIFS="$IFS"
    IFS="$nl"
    repo_folder_structure=$(find "$base_folder" -maxdepth 1 -mindepth 1 -type d ! -name "_site" ! -name "pics" ! -name "_posts" ! -name "styles" ! -name "_layouts" | sort)

    for dir in $repo_folder_structure; do
        local entry_name=$(basename "$dir")
        local parent_dir="$(dirname "$base_folder")"
        local indent=$((level * 2))
        local relative_path=$(echo "$dir" | sed "s|$parent_dir||")
        if [[ $level -eq 0 ]]; then
            relative_path=$(echo "$dir" | sed "s|$base_folder||")
        fi

        local suffix="https://mars9n9.github.io$relative_path"

        if [[ -f "$dir/ix.md" ]]; then
            # Generate the URL

            if [[ $level -eq 0 ]]; then
                suffix="https://mars9n9.github.io/$entry_name"
            fi
            toc+=$(printf '%*s' $indent)$(printf '* [%s](%s/ix.html)' $entry_name $(echo "$suffix" | sed "s| |%20|g"))$nl
        else
            # If ix.md does not exist, show the folder name as plain text
            toc+=$(printf '%*s' $indent)$(printf '* %s' $entry_name)$nl
        fi

        # Recursively call for subdirectories
        toc+=$(generate_toc "$dir" "$filetype_filter" $((level + 1)))$nl

        # Process Markdown files
        local pages=()
        local md_files
        IFS="$nl"
        md_files=$(find "$dir" -maxdepth 1 -type f -name "$filetype_filter" ! -name "ix.md")

        for md in $md_files; do
            file_name=$(grep -m 1 '^#' "$md" | sed 's|^#\s*||')
            unset IFS
            if [[ -z "$file_name" ]]; then
                file_name=$(basename "$md" .md) # If no header found, use the file name
            fi

            local suffix="https://mars9n9.github.io$relative_path"
            page_link="($suffix/$(basename "$md" .md).html)"
            pages+=("[$file_name]$(echo "$page_link" | sed "s| |%20|g")")
        done

        IFS="$nl" sorted_pages=($(sort <<<"${pages[*]}"))
        for item in "${sorted_pages[@]}"; do
            file_indent=$(((level + 1) * 2))
            toc+=$(printf '%*s' $file_indent)$(printf '* %s' $item)$nl
        done
    done

    echo "$toc"
}

# Get the current directory and check if it contains a 'docs' folder
current_directory=$(pwd)
docs_folder="$current_directory/docs"

if [[ -d "$docs_folder" ]]; then
    # Generate the Table of Contents
    toc=$(generate_toc "$docs_folder" "*.md" 0)
    # Save the TOC to index.markdown
    echo "$toc" >"$docs_folder/index.markdown"
else
    echo "No 'docs' folder found in the current directory."
    exit 1
fi
