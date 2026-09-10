import sys

def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("--cli", "cli"):
        from raw2dng.cli import main as cli_main
        raise SystemExit(cli_main(sys.argv[2:]))
    from raw2dng.gui import main as gui_main
    gui_main()

if __name__ == "__main__":
    main()
