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
  -d Destination directory (optinal)
  -m Enable auto mode (optional)

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

if [ ! -z "$dir" ]; then
    dir=Library/"$dir"
else
    dir=Library
fi
mkdir -p "$dir"

readicule() {
    # Extract title and image from the specified URL
    title=$(./go-readability -m $url | jq '.title' | tr -d \")
    image=$(./go-readability -m $url | jq '.image' | tr -d \")
    # Generate a readable HTML file
    ./go-readability $url >>"$dir/$title".html
    # Create a cover
    if [ ! -z "$image" ]; then
        wget -q "$image" -O cover
    else
        cp cover.jpg cover
    fi
    if [ -z "$title" ]; then
        title="This is Readiculous!"
    fi
    # convert HTML to EPUB
    pandoc -f html -t epub --metadata title="$title" --metadata creator="Readiculous" --metadata publisher="$url" --css=stylesheet.css --epub-cover-image=cover -o "$dir/$title".epub "$dir/$title".html
    rm cover
}

# If "-m auto" is specified
if [ "$mode" = "auto" ]; then
    file="links.txt"
    if [ ! -f "$file" ]; then
        echo "$file not found."
        exit 1
    fi
    # Read the contents of the links.txt file line-by-line
    while IFS="" read -r url || [ -n "$url" ]; do
        readicule
    done <"$file"
    exit 1
fi

if [ -z "$url" ] || [ -z "$dir" ]; then
    usage
fi

readicule

echo
echo ">>> '$title' has been saved in '$dir'"
echo
