#!/bin/bash
set -euo pipefail

# Fast, simple table-of-contents generator.
# - Uses shell globbing instead of repeated `find` calls.
# - Handles UTF-8 BOM and strips all leading `#` from the first header.

nl=$'\n'

generate_toc() {
    local base_folder="$1"
    local filetype_filter="$2"
    local level="$3"
    local toc=""

    # Collect immediate subdirectories, excluding common site folders.
    local -a subdirs=()
    for d in "$base_folder"/*; do
        [ -d "$d" ] || continue
        local name=$(basename "$d")
        case "$name" in
            _site|pics|_posts|styles|_layouts) continue ;;
        esac
        subdirs+=("$d")
    done

    # Sort directories by name for stable output
    if [ ${#subdirs[@]} -gt 0 ]; then
        IFS=$'\n' subdirs=( $(printf '%s\n' "${subdirs[@]}" | sort) )
        unset IFS
    fi

    for dir in "${subdirs[@]}"; do
        local entry_name=$(basename "$dir")
        local indent=$((level * 2))

        # Compute relative path similarly to previous behaviour
        local parent_dir="$(dirname "$base_folder")"
        local relative_path=${dir#$parent_dir}
        if [[ $level -eq 0 ]]; then
            relative_path=${dir#$base_folder}
        fi

        local suffix="https://mars9n9.github.io${relative_path// /%20}"

        if [[ -f "$dir/ix.md" ]]; then
            if [[ $level -eq 0 ]]; then
                suffix="https://mars9n9.github.io/${entry_name// /%20}"
            fi
            toc+=$(printf '%*s' $indent)$(printf '* [%s](%s/ix.html)' "$entry_name" "$suffix")$nl
        else
            toc+=$(printf '%*s' $indent)$(printf '* %s' "$entry_name")$nl
        fi

        # Recurse into subdirectories
        toc+=$(generate_toc "$dir" "$filetype_filter" $((level + 1)))$nl

        # Gather markdown pages in this directory (skip ix.md)
        local -a pages=()
        for md in "$dir"/*.md; do
            [ -f "$md" ] || continue
            [[ "$(basename "$md")" == "ix.md" ]] && continue

            # Extract first heading, remove BOM and all leading hashes/spaces.
            local file_name
            file_name=$(sed '1s/^\xEF\xBB\xBF//' "$md" | grep -m1 '^[[:space:]]*#' || true)
            if [[ -n "$file_name" ]]; then
                file_name=$(printf '%s' "$file_name" | sed 's/^[[:space:]]*#\+ *//')
            else
                file_name=$(basename "$md" .md)
            fi

            local page_slug=$(basename "$md" .md)
            local page_link="https://mars9n9.github.io${relative_path// /%20}/${page_slug// /%20}.html"
            pages+=("* [$file_name]($page_link)")
        done

        # Sort pages alphabetically (by the whole markdown line) and append with correct indent
        if [ ${#pages[@]} -gt 0 ]; then
            IFS=$'\n' pages=( $(printf '%s\n' "${pages[@]}" | sort) )
            unset IFS
            for p in "${pages[@]}"; do
                local file_indent=$(((level + 1) * 2))
                toc+=$(printf '%*s' $file_indent)"$p"$nl
            done
        fi
    done

    printf '%s' "$toc"
}

current_directory=$(pwd)
docs_folder="$current_directory/docs"

if [[ -d "$docs_folder" ]]; then
    toc=$(generate_toc "$docs_folder" "*.md" 0)
    echo "$toc" >"$docs_folder/index.markdown"
else
    echo "No 'docs' folder found in the current directory."
    exit 1
fi
