#!/bin/bash

# Function to recursively generate the table of contents
generate_toc() {
    local base_folder="$1"
    local filetype_filter="$2"
    local level="$3"
    local toc=""
    
    # List directories excluding specific patterns
    local repo_folder_structure
    repo_folder_structure=$(find "$base_folder" -maxdepth 1 -mindepth 1 -type d ! -name "_site" ! -name "pics" ! -name "_posts" ! -name "styles" ! -name "_layouts" | sort)
    
    for dir in $repo_folder_structure; do
        # Check if ix.md exists in the current directory
        if [[ -f "$dir/ix.md" ]]; then
            relative_path=$(echo "$dir" | sed "s|$base_folder/||")
            suffix="https://mars9n9.github.io/$relative_path"
            toc+=$(printf "%*s* [%s](%s/ix.html)\n" $((level * 2)) "" "$(basename "$dir")" "$suffix")
        else
            toc+=$(printf "%*s* %s\n" $((level * 2)) "" "$(basename "$dir")")
        fi

        # Recursively call for subdirectories
        toc+=$(generate_toc "$dir" "$filetype_filter" $((level + 1)))

        # Process Markdown files
        local pages=()
        local md_files
        md_files=$(find "$dir" -type f -name "$filetype_filter" ! -name "ix.md" | sort)

        for md in $md_files; do
            # Extract the first line starting with '#'
            file_name=$(head -n 1 "$md" | sed 's/^#\s*//')
            if [[ -z "$file_name" ]]; then
                # If no heading is found, fallback to file name without extension
                file_name=$(basename "$md" .md)
            fi

            relative_path=$(echo "$md" | sed "s|$base_folder/||" | sed "s|/[^/]*$||")
            suffix="https://mars9n9.github.io/$relative_path"
            page_link="[$file_name]($suffix/$(basename "$md" .md).html)"
            pages+=("$page_link")
        done

        # Sort pages by name and add them to TOC
        IFS=$'\n' sorted_pages=($(sort <<<"${pages[*]}"))
        unset IFS
        for item in "${sorted_pages[@]}"; do
            toc+=$(printf "%*s* %s\n" $((level + 2)) "" "$item")
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
