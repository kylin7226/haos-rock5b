
#!/bin/bash

# Rock5B specific hooks
set -e

case "$1" in
    pre-install)
        # Run before image is written to disk
        echo "Running Rock5B pre-install hooks..."
        ;;
    post-install)
        # Run after image is written to disk
        echo "Running Rock5B post-install hooks..."
        ;;
    *)
        echo "Usage: $0 {pre-install|post-install}"
        exit 1
        ;;
esac

exit 0
