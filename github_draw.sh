#!/bin/bash
Username="0x384c0"
Email="0x384c0@gmail.com"

Drawing[0]="..................................................."
Drawing[1]="....##.........###...##...#..#........##..........."
Drawing[2]="...#..#..........#..#..#..#..#.......#..#.........."
Drawing[3]="...#..#..#.#...###...##....###..###..#..#.........."
Drawing[4]="...#..#...#......#..#..#.....#..#....#..#.........."
Drawing[5]="....##...#.#...###...##......#..###...##..........."
Drawing[6]="..................................................."


git config --local user.name "${Username}"
git config --local user.email "${Email}"

# To multiple commit counts by
Multiplier=1

# Let's start 1 year ago
OneYearAgo=$(gdate --date='1 year ago' '+%Y-%m-%d')

# Get to the previous Sunday of that date a year ago
DaysToSubtract=$(gdate --date='1 year ago' '+%w')
PrevSunday=$(gdate --date=${OneYearAgo}' - '${DaysToSubtract}' days' '+%Y-%m-%d')

# Add 1 week to that date
StartDate=$(gdate --date=${PrevSunday}' + 1 weeks' '+%Y-%m-%d')
echo "Starting at ${StartDate}"

FILE_NAME="useless.txt"
touch $FILE_NAME
git add $FILE_NAME

# For each column
for col in {0..51}; do
	# for each row
	for row in {0..6}; do
		line=${Drawing[$row]}

		COMMITS=0
		if [ "${line:col:1}" = "#" ]; then
			COMMITS=10
		elif [ "${line:col:1}" = "@" ]; then
			COMMITS=7
		elif [ "${line:col:1}" = "%" ]; then
			COMMITS=4
		elif [ "${line:col:1}" = "o" ]; then
			COMMITS=1
		fi
		
		if [ $COMMITS != 0 ]; then
			for it in $(seq 1 $COMMITS); do
				echo "${StartDate} ${line:col:1} ${it}" > $FILE_NAME
				GIT_AUTHOR_DATE=$(gdate --date=${StartDate}' 12:00:00' --iso-8601='seconds') GIT_COMMITTER_DATE=$(gdate --date=${StartDate}' 12:00:00' --iso-8601='seconds') git commit ./$FILE_NAME -m "${line:col:1} ${it}"
			done
		fi
		StartDate=$(gdate --date=${StartDate}' + 1 day' '+%Y-%m-%d')
	done
done

echo "All done"
