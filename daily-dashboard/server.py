#!/usr/bin/env python3
"""All My Day – Webserver"""
import http.server, os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def log_message(self, fmt, *args):
        if args and str(args[1]) not in ("200", "304"):
            print(f"[{self.address_string()}] {fmt % args}")

if __name__ == "__main__":
    os.chdir(BASE_DIR)
    addr = ("127.0.0.1", 8347)
    httpd = http.server.HTTPServer(addr, Handler)
    print(f"All My Day Server läuft auf http://localhost:8347/public/")
    httpd.serve_forever()
