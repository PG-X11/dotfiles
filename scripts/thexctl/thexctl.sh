#~/bin/bash
#!/bin/bash

show_help() {
    cat << EOF
TheXctl, X11's own control tool
to use


EOF
}

case "$1" in
    on)
        echo "Game mode ON"
        ;;
    off)
        echo "Game mode OFF"
        ;;
    status)
        echo "Checking status..."
        ;;
    -h|--help|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'xesctl --help' for usage."
        exit 1
        ;;
esac
