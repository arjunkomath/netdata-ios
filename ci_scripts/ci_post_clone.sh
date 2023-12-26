#!/bin/sh

echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 --decode > "$SRCROOT/netdata/GoogleService-Info.plist"
