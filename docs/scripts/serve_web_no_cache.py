#!/usr/bin/env python3
"""Serve Flutter web build with no-cache headers (local dev)."""
import http.server
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8080


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


if __name__ == "__main__":
    os.chdir(ROOT)
    print(f"Serving (no cache): {ROOT}")
    print(f"Open: http://localhost:{PORT}/")
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
