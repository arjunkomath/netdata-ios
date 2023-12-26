#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.

echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 --decode > "../netdata/GoogleService-Info.plist" || {
    echo "Failed to decode and write GoogleService-Info.plist"
    exit 1
}
