#!/bin/bash

echo "===========================Starting==========================="
cleanup_and_exit() {
    # Kill all child processes started by the script
    #pkill -P $$

    # Exit the script
    exit 1
}

# Set up trap to call cleanup_and_exit() when SIGINT signal is received (Ctrl+C)
trap cleanup_and_exit SIGINT

# Check if segments from previous interrupted downloads exist
segment_files=$(ls -1 file*.mp4)
if [[ -z "$segment_files" ]]; then
    echo "No previous segment found. Starting..."
	segment_start_option=""
else
    num_segments=$(ls -1 file*.mp4 | wc -l)
    last_segment=$((num_segments - 1))
	segment_start_option="-segment_start_number $last_segment"
    echo "Previous segment found. Continuing..."
fi

# Function to check if a string starts with a specific prefix
starts_with() {
    case $2 in
        "$1"*) return 0;;
        *) return 1;;
    esac
}

# Function to check if a string ends with a specific suffix
ends_with() {
    case $2 in
        *"$1") return 0;;
        *) return 1;;
    esac
}

# Check if $1/$2/$3 starts with "https" and ends with ".m3u8"
if starts_with "https" "$1" && ends_with ".m3u8" "$1"; then
    vidlink=$1
elif starts_with "https" "$2" && ends_with ".m3u8" "$2"; then
    vidlink=$2
elif starts_with "https" "$3" && ends_with ".m3u8" "$3"; then
    vidlink=$3
else
	echo "Please Enter the proper M3U8 link."
	exit 0
fi

# Check if $1/$2/$3 starts with "https" and ends with ".vtt"
if starts_with "https" "$1" && ends_with ".vtt" "$1"; then
    sublink=$1
elif starts_with "https" "$2" && ends_with ".vtt" "$2"; then
    sublink=$2
elif starts_with "https" "$3" && ends_with ".vtt" "$3"; then
    sublink=$3
else
	sublink=""
fi

# Check if $1/$2/$3 is a normal text without extensions or URL
if [[ ! $1 =~ \.|/ ]]; then
    vidfile=$1
elif [[ ! $2 =~ \.|/ ]]; then
    vidfile=$2
elif [[ ! $3 =~ \.|/ ]]; then
    vidfile=$3
else
	vidfile="video"
fi


echo "vidlink: $vidlink"
echo "sublink: $sublink"
echo "vidfile: $vidfile"

# Run FFmpeg command and capture output
if [[ -z "$sublink" ]]; then 
	ffmpeg -hide_banner -loglevel quiet -i "$vidlink" -c:v copy -c:a copy -c:s mov_text -stats -flags +global_header -segment_time 60 -f segment file%03d.mp4
else
	ffmpeg -hide_banner -loglevel quiet -i "$vidlink" -i "$sublink" -c:v copy -c:a copy -c:s mov_text -stats -flags +global_header -segment_time 60 -f segment file%03d.mp4
fi

printf "file '%s'\n" file*.mp4 >> ls.txt

ffmpeg -f concat -i ls.txt -c copy -scodec mov_text -fflags +genpts "$vidfile.mp4"

rm -rf $(ls -1 file*.mp4)

rm -rf ls.txt

echo ""  # Print a newline after the progress bar is complete

cleanup_and_exit