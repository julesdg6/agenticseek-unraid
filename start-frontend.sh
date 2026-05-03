#!/usr/bin/env sh
# Generate a runtime configuration file so the backend URL can be updated at
# container startup without rebuilding the image.  The file is served as a
# static asset and its value is picked up by the React application via
# window.AGENTICSEEK_BACKEND_URL before falling back to the compile-time
# REACT_APP_BACKEND_URL env var.
BACKEND_URL="${REACT_APP_BACKEND_URL:-http://localhost:7777}"
printf "window.AGENTICSEEK_BACKEND_URL = '%s';\n" "$BACKEND_URL" \
    > /frontend/public/runtime-config.js
exec npm start
