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
# Wait until the server answers instead of sleeping a fixed time (up to ~30 s).
PORT="${FRAMEBACK_PORT:-4747}"
i=0
until node -e "fetch('http://127.0.0.1:$PORT/api/health').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"; do
  i=$((i+1))
  if [ "$i" -ge 60 ] || ! kill -0 "$SERVER" 2>/dev/null; then
    echo "frameback: server did not become healthy" >&2
    exit 1
  fi
  sleep 0.5
done
echo "$V" | tail -n +2 | while IFS= read -r f; do
  frameback open "$f" --no-open --port "${FRAMEBACK_PORT:-4747}" || true
done
wait $SERVER
