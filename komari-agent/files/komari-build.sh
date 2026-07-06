#!/bin/sh
# Build helper for komari-agent — called from Makefile Build/Compile
# Usage: komari-build.sh <build_dir> <arch> <download_url> <sha256_url|none> <ghproxy|none>
set -e

BUILD_DIR="$1"
KOMARI_ARCH="$2"
DOWNLOAD_URL="$3"
SHA256_URL="$4"
GHPROXY="$5"

BINARY="${BUILD_DIR}/komari-agent"

echo "Downloading: ${DOWNLOAD_URL}"
if command -v curl >/dev/null 2>&1; then
	curl -fL -s -o "${BINARY}" "${DOWNLOAD_URL}" || { echo "ERROR: Download failed (HTTP error or not found)"; exit 1; }
else
	wget -q -O "${BINARY}" "${DOWNLOAD_URL}" || { echo "ERROR: Download failed (HTTP error or not found)"; exit 1; }
fi

chmod +x "${BINARY}"

FILE_SIZE=$(stat -c%s "${BINARY}" 2>/dev/null || stat -f%z "${BINARY}" 2>/dev/null)
echo "Binary size: ${FILE_SIZE} bytes"
if [ "${FILE_SIZE}" -lt 524288 ]; then
	echo "ERROR: File too small — download may have failed"
	rm -f "${BINARY}"
	exit 1
fi

if [ "${SHA256_URL}" = "none" ]; then
	echo "Skipping SHA256 (no checksums available)"
	exit 0
fi

echo "Verifying SHA256..."
SUMS_FILE="${BUILD_DIR}/SHA256SUMS"
if ! curl -L -s -o "${SUMS_FILE}" "${SHA256_URL}" || [ ! -s "${SUMS_FILE}" ]; then
	echo "WARNING: SHA256SUMS unavailable, skipping"
	rm -f "${SUMS_FILE}"
	exit 0
fi

EXPECTED=$(grep -E "komari-agent-linux-${KOMARI_ARCH}(\$|[^a-zA-Z0-9])" "${SUMS_FILE}" | awk '{print $1}' | head -n1)
if [ -z "${EXPECTED}" ]; then
	echo "WARNING: ${KOMARI_ARCH} not in SHA256SUMS, skipping"
	rm -f "${SUMS_FILE}"
	exit 0
fi

ACTUAL=$(sha256sum "${BINARY}" | awk '{print $1}')
if [ "${EXPECTED}" = "${ACTUAL}" ]; then
	echo "SHA256 OK"
else
	echo "ERROR: SHA256 mismatch (expected: ${EXPECTED}, actual: ${ACTUAL})"
	rm -f "${BINARY}" "${SUMS_FILE}"
	exit 1
fi

rm -f "${SUMS_FILE}"
