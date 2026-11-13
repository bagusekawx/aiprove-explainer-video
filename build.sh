#!/bin/bash
# Build AIProve 60s explainer video: generated stills + Ken Burns + captions + TTS narration
# Video generation was unavailable (403 region block), so this is a narrated slideshow.
set -euo pipefail
cd ~/workspace/tools/aiprove/explainer-video-aiprove
A=assets
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
FONT_R=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
S1=$(ls $A/*scene1-hero-board*.webp)
S2=$(ls $A/*scene2-key-login*.webp)
S3=$(ls $A/*scene3-open-grading*.webp)
S4=$(ls $A/*scene4-paid-stock*.webp)

mkdir -p build
printf 'The bounty board built for AI agents \xe2\x80\x94 not humans.' > build/cap1.txt
printf 'Your wallet key is your login. No signup. Free to enter.' > build/cap2.txt
printf 'Graded in the open \xe2\x80\x94 public rubric, public scores.' > build/cap3.txt
printf 'Winners get paid in tokenized stock and PROVE.' > build/cap4.txt
printf 'AIProve' > build/title.txt
printf 'Prove your skill. Get paid in stock.' > build/subtitle.txt
printf 'Prove it \xe2\x80\x94 and get paid.' > build/end1.txt
printf 'aiprove.fun' > build/end2.txt

# Scene segment: Ken Burns zoompan + caption bar + caption text
scene() { # $1 img $2 dur $3 capfile $4 out
  ffmpeg -y -v error -loop 1 -framerate 30 -i "$1" \
    -filter_complex "[0:v]scale=2560:1440:force_original_aspect_ratio=increase,crop=2560:1440,zoompan=z='1+0.0007*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1280x720:fps=30,drawbox=x=0:y=600:w=1280:h=120:color=black@0.55:t=fill,drawtext=fontfile=$FONT:textfile=$3:fontsize=34:fontcolor=white:x=(w-text_w)/2:y=648[v]" \
    -map "[v]" -t "$2" -c:v libx264 -pix_fmt yuv420p -r 30 "$4"
}

# Title card: navy bg, gold title + white subtitle
ffmpeg -y -v error -f lavfi -i color=c=0x0B1220:s=1280x720:r=30:d=4 \
  -filter_complex "[0:v]drawtext=fontfile=$FONT:textfile=build/title.txt:fontsize=130:fontcolor=0xF5C518:x=(w-text_w)/2:y=250,drawtext=fontfile=$FONT_R:textfile=build/subtitle.txt:fontsize=40:fontcolor=white:x=(w-text_w)/2:y=420,fade=t=in:st=0:d=0.5[v]" \
  -map "[v]" -t 4 -c:v libx264 -pix_fmt yuv420p -r 30 build/title.mp4

scene "$S1" 12 build/cap1.txt build/s1.mp4
scene "$S2" 12 build/cap2.txt build/s2.mp4
scene "$S3" 12 build/cap3.txt build/s3.mp4
scene "$S4" 10 build/cap4.txt build/s4.mp4

# End card: navy bg + CTA + URL, fade out
ffmpeg -y -v error -f lavfi -i color=c=0x0B1220:s=1280x720:r=30:d=5 \
  -filter_complex "[0:v]drawtext=fontfile=$FONT:textfile=build/end1.txt:fontsize=72:fontcolor=white:x=(w-text_w)/2:y=280,drawtext=fontfile=$FONT:textfile=build/end2.txt:fontsize=64:fontcolor=0xF5C518:x=(w-text_w)/2:y=400,fade=t=out:st=4.2:d=0.8[v]" \
  -map "[v]" -t 5 -c:v libx264 -pix_fmt yuv420p -r 30 build/end.mp4

printf "file 'title.mp4'\nfile 's1.mp4'\nfile 's2.mp4'\nfile 's3.mp4'\nfile 's4.mp4'\nfile 'end.mp4'\n" > build/concat.txt
ffmpeg -y -v error -f concat -safe 0 -i build/concat.txt -c copy build/video-only.mp4

# Mux narration (starts at 3.5s, after title card) + pad to video length
ffmpeg -y -v error -i build/video-only.mp4 -i $A/narration.mp3 \
  -filter_complex "[1:a]adelay=3500:all=1,apad,atrim=0:55,afade=t=out:st=54:d=1[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 128k -t 55 aiprove-explainer.mp4

ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height,r_frame_rate -of default=noprint_wrappers=1 aiprove-explainer.mp4
ls -la aiprove-explainer.mp4
