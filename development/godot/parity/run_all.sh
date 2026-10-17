#!/usr/bin/env bash
set -euo pipefail
PARITY="$(cd "$(dirname "$0")" && pwd)"
for scenario in "$PARITY"/scenarios/*.json; do
	echo "==> $(basename "$scenario")"
	"$PARITY/run_pair.sh" "$scenario"
done
