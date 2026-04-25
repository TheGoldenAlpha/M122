#!/usr/bin/env python3
"""All My Day – Webserver mit Subscribe/Unsubscribe API"""
import http.server, json, os, re
from datetime import datetime

BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
DATA_DIR  = os.path.join(BASE_DIR, "data")
SUBS_FILE = os.path.join(DATA_DIR, "subscribers.json")

def load_subs():
    try:
        with open(SUBS_FILE, encoding="utf-8") as f:
            return json.load(f)
    except:
        return []

def save_subs(subs):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(SUBS_FILE, "w", encoding="utf-8") as f:
        json.dump(subs, f, ensure_ascii=False, indent=2)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length).decode())
        except:
            body = {}

        if self.path == "/subscribe":
            result = self._subscribe(body)
        elif self.path == "/unsubscribe":
            result = self._unsubscribe(body)
        elif self.path == "/subscribers":
            result = self._list_subs(body)
        else:
            result = {"ok": False, "error": "Unbekannter Endpunkt"}

        resp = json.dumps(result, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(resp)))
        self._cors()
        self.end_headers()
        self.wfile.write(resp)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _subscribe(self, data):
        email = data.get("email", "").strip().lower()
        time  = data.get("time", "07:00")
        name  = data.get("name", "").strip()

        if not re.match(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
            return {"ok": False, "error": "Ungültige E-Mail-Adresse."}
        if time not in ("06:00", "07:00", "08:00"):
            time = "07:00"

        subs = load_subs()
        if any(s.get("email","").lower() == email for s in subs):
            return {"ok": False, "error": "Diese E-Mail ist bereits angemeldet!"}

        subs.append({
            "email": email,
            "name":  name or email.split("@")[0],
            "time":  time,
            "since": datetime.now().strftime("%Y-%m-%d"),
        })
        save_subs(subs)
        print(f"[subscribe] {email} @ {time}")
        return {"ok": True, "message": f"Erfolgreich angemeldet! Du bekommst täglich um {time} Uhr eine Nachricht."}

    def _unsubscribe(self, data):
        email = data.get("email", "").strip().lower()
        subs  = load_subs()
        new   = [s for s in subs if s.get("email","").lower() != email]
        if len(new) == len(subs):
            return {"ok": False, "error": "E-Mail nicht gefunden."}
        save_subs(new)
        print(f"[unsubscribe] {email}")
        return {"ok": True, "message": "Erfolgreich abgemeldet."}

    def _list_subs(self, data):
        # Einfacher Admin-Schutz
        if data.get("key") != "allmyday-admin":
            return {"ok": False, "error": "Nicht autorisiert."}
        subs = load_subs()
        return {"ok": True, "count": len(subs), "subscribers": subs}

    def log_message(self, fmt, *args):
        # Nur Fehler und API-Calls ausgeben
        if args and (str(args[1]) not in ("200", "304") or "/subscribe" in str(args[0])):
            print(f"[{self.address_string()}] {fmt % args}")

if __name__ == "__main__":
    os.chdir(BASE_DIR)
    addr = ("127.0.0.1", 8347)
    httpd = http.server.HTTPServer(addr, Handler)
    print(f"All My Day Server läuft auf http://localhost:8347/public/")
    print(f"Subscribers: {DATA_DIR}/subscribers.json")
    httpd.serve_forever()
