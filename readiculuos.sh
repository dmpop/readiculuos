#!/usr/bin/env bash
if [ ! -x "$(command -v wget)" ] || [ ! -x "$(command -v pandoc)" ] || [ ! -x "$(command -v jq)" ]; then
    echo "Make sure that the required tools are installed"
    exit 1
fi

# Usage prompt
usage() {
    cat <<EOF
$0 [OPTIONS]
------
$0 transforms web pages pages into readable EPUB files.

USAGE:
------
  $0 -u <URL> -d <dir> -m auto

OPTIONS:
--------
  -u Source URL
  -d Destination directory
  -m Enable auto mode

EXAMPLES:
---------
$0 -u https://psyche.co/guides/how-to-approach-the-lifelong-project-of-language-learning -d "Language"
$0 -m auto

EOF
    exit 1
}

#Read the specfied parameters
while getopts "u:d:m:" opt; do
    case ${opt} in
    u)
        url=$OPTARG
        ;;
    d)
        dir=$OPTARG
        ;;
    m)
        mode=$OPTARG
        ;;
    \?)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

# Add all fonts
for f in fonts/*.ttf; do
    embed_fonts+="--epub-embed-font="
    embed_fonts+=$f
    embed_fonts+=" "
done

# If "-m auto" is specified
if [ "$mode" = "auto" ]; then
    file="links.txt"
    if [ ! -f "$file" ]; then
        echo "$file not found."
        exit 1
    fi
    dir="Library"
    mkdir -p "$dir"
    # Read the contents of the links.txt file line-by-line
    while IFS="" read -r url || [ -n "$url" ]; do
        # For each URL, extract title and image
        title=$(./go-readability -m $url | jq '.title' | tr -d \")
        image=$(./go-readability -m $url | jq '.image' | tr -d \")
        # generate a readable HTML file
        ./go-readability $url >>"$dir/$title".html
        # save image as cover
        wget -q "$image" -O cover
        # convert HTML to EPUB
        pandoc -f html -t epub --metadata title="$title" --metadata creator="Readiculous" --metadata publisher="$url" --css=stylesheet.css $embed_fonts --epub-cover-image=cover -o "$dir/$title".epub "$dir/$title".html
        rm cover
    done <"$file"
    exit 1
fi

if [ -z "$url" ] || [ -z "$dir" ]; then
    usage
fi

dir=Library/"$dir"
mkdir -p "$dir"

# Extract title and image from the specified URL
title=$(./go-readability -m $url | jq '.title' | tr -d \")
image=$(./go-readability -m $url | jq '.image' | tr -d \")
# Generate a readable HTML file
./go-readability $url >>"$dir/$title".html
# Save the image as cover
wget -q "$image" -O cover
# convert HTML to EPUB
pandoc -f html -t epub --metadata title="$title" --metadata creator="Readiculous" --metadata publisher="$url" --css=stylesheet.css $embed_fonts --epub-cover-image=cover -o "$dir/$title".epub "$dir/$title".html
rm cover

echo
echo ">>> '$title' has been saved in '$dir'"
echo