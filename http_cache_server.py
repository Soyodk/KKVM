import argparse
import functools
import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=22003, type=int)
    args = parser.parse_args()

    args.root.mkdir(parents=True, exist_ok=True)
    mimetypes.add_type("application/octet-stream", ".lua")
    handler = functools.partial(SimpleHTTPRequestHandler, directory=str(args.root))
    server = ThreadingHTTPServer((args.host, args.port), handler)
    server.serve_forever()


if __name__ == "__main__":
    main()