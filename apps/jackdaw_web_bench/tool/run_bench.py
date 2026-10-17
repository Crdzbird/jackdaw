"""Builds the browser bench, serves it cross-origin isolated so the page
clock is precise, runs it in headless Chrome and prints the medians.

Usage: python3 tool/run_bench.py [js|wasm] [runs] [entry]

The entry is a page in web/, main by default; apply_breakdown times the
steps of applying the screen's messages.
"""
import json
import os
import shutil
import statistics
import subprocess
import sys
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def build(mode, entry):
    out = os.path.join(HERE, 'build', mode)
    os.makedirs(out, exist_ok=True)
    if mode == 'js':
        target = os.path.join(out, 'main.dart.js')
        subprocess.run(['dart', 'compile', 'js', '-O2', '-o', target, f'web/{entry}.dart'], cwd=HERE, check=True, capture_output=True)
        shutil.copy(os.path.join(HERE, 'web', 'index.html'), os.path.join(out, 'index.html'))
    if mode == 'wasm':
        target = os.path.join(out, 'main.wasm')
        subprocess.run(['dart', 'compile', 'wasm', '-O2', '-o', target, f'web/{entry}.dart'], cwd=HERE, check=True, capture_output=True)
        shutil.copy(os.path.join(HERE, 'web', 'index_wasm.html'), os.path.join(out, 'index.html'))
    return out


def run_once(root):
    done = threading.Event()
    result = {}

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=root, **kwargs)

        def end_headers(self):
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
            self.send_header('Cache-Control', 'no-store')
            super().end_headers()

        def guess_type(self, path):
            if path.endswith('.mjs'):
                return 'text/javascript'
            return super().guess_type(path)

        def do_POST(self):
            body = self.rfile.read(int(self.headers['Content-Length']))
            if self.path == '/log':
                print('page:', json.loads(body), file=sys.stderr, flush=True)
                self.send_response(204)
                self.end_headers()
                return
            result['rows'] = json.loads(body)
            if 'error' in result['rows'][0]:
                print('page error:', result['rows'][0], file=sys.stderr, flush=True)
            self.send_response(204)
            self.end_headers()
            done.set()

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    profile = tempfile.mkdtemp()
    chrome = subprocess.Popen([
        CHROME, '--headless=new', '--no-first-run', '--no-default-browser-check',
        f'--user-data-dir={profile}', '--js-flags=--expose-gc',
        '--enable-blink-features=ForceEagerMeasureMemory', '--disable-background-timer-throttling',
        '--disable-renderer-backgrounding', '--window-size=1280,2000',
        f'http://127.0.0.1:{server.server_port}/index.html',
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    finished = done.wait(1800)
    chrome.kill()
    chrome.wait()
    server.shutdown()
    shutil.rmtree(profile, ignore_errors=True)
    if not finished:
        raise SystemExit('the bench page sent no result')
    return result['rows']


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'js'
    runs = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    entry = sys.argv[3] if len(sys.argv) > 3 else 'main'
    root = build(mode, entry)
    rows = [row for _ in range(runs) for row in run_once(root)]
    html = {r['side']: r.pop('html') for r in rows if 'html' in r}
    for side, text in html.items():
        with open(os.path.join(root, side + '.html'), 'w') as out:
            out.write(text)
    sides = sorted({row['side'] for row in rows})
    keys = sorted({k for r in rows for k in r if k != 'side'})
    print(f"{mode}: medians; rows ending in .memory are the memory rounds")
    print(f"{'':24}" + ''.join(f"{s[:13]:>14}" for s in sides))
    for key in keys:
        values = [[r[key] for r in rows if r['side'] == s and key in r] for s in sides]
        print(f"{key:24}" + ''.join(f"{statistics.median(v):14.3f}" if v else f"{'':>14}" for v in values))
    print('BENCH ' + json.dumps({'mode': mode, 'rows': rows}))


main()
