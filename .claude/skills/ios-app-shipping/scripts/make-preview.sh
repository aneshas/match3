#!/bin/sh
# Builds the App Store app preview (iPhone, 886x1920, 28 s, music) from a headless
# simulator recording. See PUBLISH.md step 4 and CLAUDE.md "Headless simulator verification".
#
#   UDID=... BUNDLE_ID=... APP_PATH=... MUSIC=... make-preview.sh <work dir> <out.mp4>
#
# Needs: a booted "match3-test (Claude)" simulator with the Debug app installed and a fresh
# state (uninstall first so level 1 plays), ffmpeg, and the clean level-1 board and Good Job
# screenshots the disc patch is taken from (see below). Steps:
#   1. simctl recordVideo of 36 s of autoplay on level 1 (Play -> level -> Good Job).
#   2. preview-clean: the Duo simulator paints its cover camera as a black disc in every
#      recorded frame; patch it from a clean screenshot (board) or by interpolation (Good Job).
#   3. compose-screenshot makes the 886x1920 background with the caption and prints where
#      the clip goes; preview-roundmask makes the rounded mask for it.
#   4. ffmpeg: 30 fps, H.264 High 4.0 at ~11 Mbit/s, music as stereo AAC 256 kbit/s 48 kHz.
set -e
WORK=$1; OUT=$2; UDID=${UDID:?set UDID to your test simulator}; B=${BUNDLE_ID:?set BUNDLE_ID}; APP=${APP_PATH:?set APP_PATH to the built .app}
T=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$WORK"; cd "$WORK"
for t in compose-screenshot preview-clean preview-roundmask; do [ -x $t ] || swiftc -O "$T/$t.swift" -o $t; done

# 1. Record (the app needs ~4 s to show the board; the Good Job of level 1 ends around 32 s).
xcrun simctl uninstall $UDID $B; xcrun simctl install $UDID $APP
xcrun simctl io $UDID recordVideo --display=1 --codec h264 --force raw.mp4 & REC=$!; sleep 2
env SIMCTL_CHILD_APP_MUTE=1 SIMCTL_CHILD_APP_AUTOSTART=1 SIMCTL_CHILD_APP_AUTOPLAY=1 SIMCTL_CHILD_APP_LEVEL=1 xcrun simctl launch $UDID $B
sleep 34; kill -INT $REC; sleep 4; xcrun simctl terminate $UDID $B

# Clean screenshots for the disc patch: level 1 board (same palette as the recording) and a Good Job.
[ -f board.png ] || { env SIMCTL_CHILD_APP_MUTE=1 SIMCTL_CHILD_APP_AUTOSTART=1 SIMCTL_CHILD_APP_LEVEL=1 xcrun simctl launch $UDID $B; sleep 6
  for i in 1 2 3 4 5 6 7 8; do xcrun simctl io $UDID screenshot --display=1 b_$i.png; sleep 0.7; done; xcrun simctl terminate $UDID $B
  echo "pick a b_N.png without the black disc at the top right, copy it to board.png, and a clean Good Job screenshot to goodjob.png, then rerun"; exit 1; }

# 2. Patch the disc.
./preview-clean raw.mp4 clean.mov board.png goodjob.png

# 3. Background, clip rectangle and mask.
ffmpeg -v error -y -ss 18 -i raw.mp4 -frames:v 1 frame.png
./compose-screenshot bg.png 886 1920 frame.png "Nothing to lose. Nothing to read." > rect.txt
read _ X Y W H _ R < rect.txt
./preview-roundmask mask.png $W $H $R

# 4. Music: one of the app's loops, normalized, faded in and out.
ffmpeg -v error -y -i "${MUSIC:?set MUSIC to an audio file}" -af "loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=in:st=0:d=1.5" -ac 2 -ar 48000 -c:a aac -b:a 256k music.m4a
ffmpeg -v error -y -i bg.png -ss 4.3 -t 28 -i clean.mov -i mask.png -i music.m4a \
  -filter_complex "[1:v]fps=30,scale=$W:$H[c];[2:v]format=gray[m];[c][m]alphamerge[clip];[0:v][clip]overlay=$X:$Y:format=auto,format=yuv420p[v];[3:a]afade=t=out:st=26:d=2[a]" \
  -map "[v]" -map "[a]" -t 28 -c:v libx264 -profile:v high -level 4.0 -b:v 11M -maxrate 12M -bufsize 24M -r 30 \
  -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart "$OUT"
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,channels:format=duration -of compact "$OUT"
