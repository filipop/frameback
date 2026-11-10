#!/bin/sh
# Container entrypoint: `frameback open` needs a video to start, so wait for one in /videos,
# start the server on the first, then register the rest. Videos added later:
#   docker exec frameback frameback open /videos/<file> --no-open
find_videos() {
  find /videos -maxdepth 3 -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.webm' \) -not -path '*/review/*' | sort
}

while :; do
  V="$(find_videos)"
  [ -n "$V" ] && break
  echo "frameback: no videos in /videos yet, waiting..."
  sleep 5
done

FIRST="$(echo "$V" | head -n 1)"
frameback open "$FIRST" --no-open --port "${FRAMEBACK_PORT:-4747}" &
SERVER=$!
sleep 3
echo "$V" | tail -n +2 | while IFS= read -r f; do
  frameback open "$f" --no-open --port "${FRAMEBACK_PORT:-4747}" || true
done
wait $SERVER
