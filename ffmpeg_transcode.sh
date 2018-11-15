#!/bin/sh

set -e

LOG_FILE=/Users/king/Downloads/ffmpeg_transcode.log
INPUT_FILE=/Users/king/Downloads/4K.mp4
OUTPUT_DIR=/Users/king/Downloads

function transcode() {

	if [[ -f $LOG_FILE ]]; then
		echo "rm logfile"
		rm -rf $LOG_FILE
	fi

	echo "1080: start time $(date +%s)" >> $LOG_FILE
	ffmpeg -y -i $INPUT_FILE -s 1920x1080 -b:v 6000k -r 30 -vcodec h264_videotoolbox -b:a 64k -ar 44.1k -ac 1 -acodec aac $OUTPUT_DIR/ffmpeg_mac_1080.mp4
	echo "1080: end time $(date +%s)" >> $LOG_FILE

	echo "720: start time $(date +%s)" >> $LOG_FILE
	ffmpeg -y -i $INPUT_FILE -s 1280x720 -b:v 4000k -r 30 -vcodec h264_videotoolbox -b:a 64k -ar 44.1k -ac 1 -acodec aac $OUTPUT_DIR/ffmpeg_mac_720.mp4
	echo "720: end time $(date +%s)" >> $LOG_FILE

	echo "540: start time $(date +%s)" >> $LOG_FILE
	ffmpeg -y -i $INPUT_FILE -s 960x540 -b:v 3000k -r 30 -vcodec h264_videotoolbox -b:a 64k -ar 44.1k -ac 1 -acodec aac $OUTPUT_DIR/ffmpeg_mac_540.mp4
	echo "540: end time $(date +%s)" >> $LOG_FILE

	echo "480: start time $(date +%s)" >> $LOG_FILE
	ffmpeg -y -i $INPUT_FILE -s 640x480 -b:v 2000k -r 30 -vcodec h264_videotoolbox -b:a 64k -ar 44.1k -ac 1 -acodec aac $OUTPUT_DIR/ffmpeg_mac_480.mp4
	echo "480: end time $(date +%s)" >> $LOG_FILE

	cat $LOG_FILE
}

function calculate_time() {
	hours=$(echo "(1542198120 - 1542198042) % (24 * 3600) / 3600" | bc)
	minutes=$(echo "(1542198120 - 1542198042) % 3600 / 60" | bc)
	second=$(echo "(1542198120 - 1542198042) % 60" | bc)
	echo "1080: $hours:$minutes:$second"

	hours=$(echo "(1542198194 - 1542198120) % (24 * 3600) / 3600" | bc)
	minutes=$(echo "(1542198194 - 1542198120) % 3600 / 60" | bc)
	second=$(echo "(1542198194 - 1542198120) % 60" | bc)
	echo "720: $hours:$minutes:$second"

	hours=$(echo "(1542198259 - 1542198194) % (24 * 3600) / 3600" | bc)
	minutes=$(echo "(1542198259 - 1542198194) % 3600 / 60" | bc)
	second=$(echo "(1542198259 - 1542198194) % 60" | bc)
	echo "540: $hours:$minutes:$second"

	hours=$(echo "(1542198321 - 1542198259) % (24 * 3600) / 3600" | bc)
	minutes=$(echo "(1542198321 - 1542198259) % 3600 / 60" | bc)
	second=$(echo "(1542198321 - 1542198259) % 60" | bc)
	echo "480: $hours:$minutes:$second"
}

calculate_time
