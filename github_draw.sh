#!/bin/bash

# Usage: git checkout master && git reset --hard only_script && sh github_draw.sh

#################### constants

FILE_NAME="useless.txt"

IMAGE_FILE=picture.png
IMAGE_WIDTH=52
IMAGE_HEIGHT=7

USERNAME="0x384c0"
EMAIL="0x384c0@gmail.com"

#################### logging

function banner {
	echo ""
	echo "$(tput setaf 5; tput bold;)######## $1 #######$(tput sgr0)"
	echo ""
}
function warning {
	echo "$(tput setaf 3; tput bold;)WARNING: $1$(tput sgr0)"
}
function info {
	echo "$(tput setaf 2; tput bold;)INFO: $1$(tput sgr0)"
}
function error {
	echo "$(tput setaf 1; tput bold;)ERROR: $1$(tput sgr0)"
	exit 1
}

#################### image read

image_resize() {
	RESIZED_IMAGE_FILE="resized_$IMAGE_FILE"


	local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 $IMAGE_FILE)
	local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 $IMAGE_FILE)

	if [ "$width" -ne "$IMAGE_WIDTH" ] || [ "$height" -ne "$IMAGE_HEIGHT" ]; then
		warning "Image size $width x $height does not match required values $IMAGE_WIDTH x $IMAGE_HEIGHT and will be resized"
		ffmpeg -i $IMAGE_FILE -vf scale=$IMAGE_WIDTH:$IMAGE_HEIGHT -y -loglevel error $RESIZED_IMAGE_FILE
		IMAGE_FILE=$RESIZED_IMAGE_FILE
	fi
}

image_to_list() {
	local raw_image=$(ffmpeg -i $IMAGE_FILE -pix_fmt rgb24 -f rawvideo -hide_banner -loglevel error - | od -An -v -tu1)
	local raw_image=( $raw_image )

	local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 $IMAGE_FILE)
	local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 $IMAGE_FILE)

	if [ "$width" -ne "$IMAGE_WIDTH" ] || [ "$height" -ne "$IMAGE_HEIGHT" ]; then
		error "Image size $width x $height does not match required values $IMAGE_WIDTH x $IMAGE_HEIGHT."
		exit 1
	fi

	local pixel_size=3

	for i in "${!raw_image[@]}"; do
		if (( $(($i % $pixel_size )) == 0 )); then
			raw_image_r_values+=(${raw_image[$i]})
		fi
	done
}

#################### git

setup_git_user() {
	git config --local user.name "${USERNAME}"
	git config --local user.email "${EMAIL}"
}

generate_commits(){
	# To multiple commit counts by
	Multiplier=1

	# Let's start 1 year ago
	OneYearAgo=$(gdate --date='1 year ago' '+%Y-%m-%d')

	# Get to the previous Sunday of that date a year ago
	DaysToSubtract=$(gdate --date='1 year ago' '+%w')
	PrevSunday=$(gdate --date=${OneYearAgo}' - '${DaysToSubtract}' days' '+%Y-%m-%d')

	# Add 1 week to that date
	StartDate=$(gdate --date=${PrevSunday}' + 1 weeks' '+%Y-%m-%d')

	rm -rf $FILE_NAME
	touch $FILE_NAME
	git add $FILE_NAME

	# For each column
	local rows=$((IMAGE_HEIGHT - 1))
	local columns=$((IMAGE_WIDTH - 1))

	local png_max=255
	local commits_canvas_max=10

	info "Starting at ${StartDate}"

	for row in $(seq 0 $rows); do
		for col in $(seq 0 $columns); do
		
			index=$(($col + $row * $columns))
			value=${raw_image_r_values[index]}
			COMMITS=$((commits_canvas_max * value / png_max ))
			COMMITS=$(printf '%.*f\n' 0 $COMMITS)
			
			if [ $COMMITS != 0 ]; then
				for it in $(seq 1 $COMMITS); do
					echo "${StartDate} $COMMITS ${it}" >> $FILE_NAME
					GIT_AUTHOR_DATE=$(gdate --date=${StartDate}' 12:00:00' --iso-8601='seconds') GIT_COMMITTER_DATE=$(gdate --date=${StartDate}' 12:00:00' --iso-8601='seconds') git commit ./$FILE_NAME -m "$COMMITS ${it}"
				done
			fi
			StartDate=$(gdate --date=${StartDate}' + 1 day' '+%Y-%m-%d')
		done
	done
}

#################### debug

print_image_data() {
	banner "image data"
	for i in "${!raw_image_r_values[@]}"; do
		printf "%s\t%s\n" "$i" "${raw_image_r_values[$i]}"
	done
}

####################
# main
####################

image_resize
image_to_list
setup_git_user
generate_commits
# print_image_data