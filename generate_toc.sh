#!/bin/bash

# Function to recursively generate the table of contents
generate_toc() {
    local base_folder="$1"
    local filetype_filter="$2"
    local level="$3"
    local toc=""
    local nl=$'\n'  # Define newline character
    
    # List directories excluding specific patterns
    local repo_folder_structure
    repo_folder_structure=$(find "$base_folder" -maxdepth 1 -mindepth 1 -type d ! -name "_site" ! -name "pics" ! -name "_posts" ! -name "styles" ! -name "_layouts" | sort)

    for dir in $repo_folder_structure; do
        local entry_name=""

        if [[ -f "$dir/ix.md" ]]; then
            # Read the first line starting with '#' from ix.md if exists
            entry_name=$(grep -m 1 '^#' "$dir/ix.md" | sed 's/^#\s*//')
            if [[ -z "$entry_name" ]]; then
                entry_name=$(basename "$dir")  # If no valid header, use the folder name
            fi
        else
            entry_name=$(basename "$dir")  # Use the folder name if ix.md is missing
        fi

        relative_path=$(echo "$dir" | sed "s|$base_folder/||")
        suffix="https://mars9n9.github.io/$relative_path"

        toc+=$(printf "%*s* [%s](%s/ix.html) $nl" $((level * 2)) "" "$entry_name" "$suffix")

        # Recursively call for subdirectories
        toc+=$(generate_toc "$dir" "$filetype_filter" $((level + 1)))

        # Process Markdown files
        local pages=()
        local md_files
        md_files=$(find "$dir" -type f -name "$filetype_filter" ! -name "ix.md" | sort)

        for md in $md_files; do
            file_name=$(grep -m 1 '^#' "$md" | sed 's/^#\s*//')
            if [[ -z "$file_name" ]]; then
                file_name=$(basename "$md" .md)  # If no header found, use the file name
            fi

            relative_path=$(echo "$md" | sed "s|$base_folder/||" | sed "s|/[^/]*$||")
            suffix="https://mars9n9.github.io/$relative_path"
            page_link="[$file_name]($suffix/$(basename "$md" .md).html)"
            pages+=("$page_link")
        done

        IFS=$'\n' sorted_pages=($(sort <<<"${pages[*]}"))
        unset IFS
        for item in "${sorted_pages[@]}"; do
            toc+=$(printf "%*s* %s$nl" $((level + 2)) "" "$item")
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
    echo "$toc" > "$docs_folder/index.markdown"
else
    echo "No 'docs' folder found in the current directory."
fi
