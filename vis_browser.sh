#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
requested_port="${1:-8000}"

if [[ "$requested_port" == "-h" || "$requested_port" == "--help" ]]; then
  echo "Usage: $0 [port]"
  exit 0
fi

if ! [[ "$requested_port" =~ ^[0-9]+$ ]] || (( requested_port < 1 || requested_port > 65535 )); then
  echo "Port must be an integer between 1 and 65535." >&2
  exit 1
fi

python_bin=""
for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1; then
    python_bin="$candidate"
    break
  fi
done

if [[ -z "$python_bin" ]]; then
  echo "Python is required to run the local server." >&2
  exit 1
fi

port="$("$python_bin" - "$requested_port" <<'PY'
import itertools
import socket
import sys

start = int(sys.argv[1])
candidates = itertools.chain(range(start, 65536), range(1024, start))

for port in candidates:
    with socket.socket() as sock:
        try:
            sock.bind(("127.0.0.1", port))
        except OSError:
            continue
        print(port)
        break
else:
    raise SystemExit("Could not find an available port.")
PY
)"

if [[ "$port" != "$requested_port" ]]; then
  echo "Port $requested_port is busy, using $port instead."
fi

echo "Serving $repo_root at http://127.0.0.1:$port/"
exec "$python_bin" -m http.server "$port" --bind 127.0.0.1 --directory "$repo_root"
