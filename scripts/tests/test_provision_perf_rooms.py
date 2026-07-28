#!/usr/bin/env python3

import json
import os
import shlex
import shutil
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "provision-perf-rooms.sh"


class MatrixState:
    def __init__(self, existing_rooms, invalid_login_once=False):
        self.room_names = dict(existing_rooms)
        self.invalid_login_once = invalid_login_once
        self.login_attempts = 0
        self.joined_rooms_requests = 0
        self.created_room_names = []
        self.sent_messages = 0


class MatrixHandler(BaseHTTPRequestHandler):
    state = None

    def log_message(self, _format, *_args):
        return

    def send_json(self, payload, status=200):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.handle_get()

    def do_POST(self):
        self.handle_post()

    def do_PUT(self):
        self.handle_put()

    def handle_get(self):
        if self.path == "/_matrix/client/v3/joined_rooms":
            self.state.joined_rooms_requests += 1
            self.send_json({"joined_rooms": list(self.state.room_names)})
            return

        prefix = "/_matrix/client/v3/rooms/"
        suffix = "/state/m.room.name"
        if self.path.startswith(prefix) and self.path.endswith(suffix):
            room_id = unquote(self.path[len(prefix) : -len(suffix)])
            self.send_json({"name": self.state.room_names[room_id]})
            return

        self.send_error(404)

    def handle_post(self):
        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length)

        if self.path == "/_matrix/client/v3/login":
            self.handle_login()
            return

        if self.path == "/_matrix/client/v3/createRoom":
            self.handle_create_room(body)
            return

        self.send_error(404)

    def handle_login(self):
        self.state.login_attempts += 1
        if self.state.invalid_login_once and self.state.login_attempts == 1:
            malformed = b"<html>Bad gateway</html>"
            self.send_response(502)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(malformed)))
            self.end_headers()
            self.wfile.write(malformed)
            return
        self.send_json({"access_token": "test-token"})

    def handle_create_room(self, body):
        room_name = json.loads(body)["name"]
        room_id = f"!created{len(self.state.created_room_names)}:test"
        self.state.created_room_names.append(room_name)
        self.state.room_names[room_id] = room_name
        self.send_json({"room_id": room_id})

    def handle_put(self):
        if "/send/m.room.message/" in self.path:
            self.state.sent_messages += 1
            self.send_json({"event_id": f"$event{self.state.sent_messages}"})
            return
        self.send_error(404)


def handler_for(state):
    return type("BoundMatrixHandler", (MatrixHandler,), {"state": state})


class ProvisionPerfRoomsTest(unittest.TestCase):
    def run_script(self, state, fail_joined_rooms_once=False):
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler_for(state))
        server_thread = threading.Thread(target=server.serve_forever, daemon=True)
        server_thread.start()

        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                env_file = temp_path / "integration.env"
                env_file.write_text(
                    "\n".join(
                        [
                            f"SERVER_URL=http://127.0.0.1:{server.server_port}",
                            "USERNAME=test-user",
                            "PASSWORD=test-password",
                        ]
                    )
                    + "\n"
                )

                fake_bin = temp_path / "bin"
                fake_bin.mkdir()
                real_curl = shutil.which("curl")
                self.assertIsNotNone(real_curl)
                curl_wrapper = fake_bin / "curl"
                curl_wrapper.write_text(
                    "#!/usr/bin/env bash\n"
                    'if [[ "${FAIL_JOINED_ROOMS_ONCE:-}" == "1" '
                    '&& "$*" == *"/joined_rooms"* '
                    '&& ! -e "$CURL_FAILURE_MARKER" ]]; then\n'
                    '  touch "$CURL_FAILURE_MARKER"\n'
                    "  printf '\\n000'\n"
                    "  exit 7\n"
                    "fi\n"
                    f"exec {shlex.quote(real_curl)} \"$@\"\n"
                )
                curl_wrapper.chmod(0o755)

                sleep_wrapper = fake_bin / "sleep"
                sleep_wrapper.write_text("#!/usr/bin/env bash\nexit 0\n")
                sleep_wrapper.chmod(0o755)

                env = os.environ.copy()
                env.update(
                    {
                        "PATH": f"{fake_bin}:{env['PATH']}",
                        "TEXT_MSG_COUNT": "1",
                        "IMAGE_COUNT": "0",
                        "FAIL_JOINED_ROOMS_ONCE": (
                            "1" if fail_joined_rooms_once else "0"
                        ),
                        "CURL_FAILURE_MARKER": str(temp_path / "curl-failed"),
                    }
                )
                return subprocess.run(
                    ["bash", str(SCRIPT_PATH), str(env_file)],
                    check=False,
                    capture_output=True,
                    env=env,
                    text=True,
                    timeout=10,
                )
        finally:
            server.shutdown()
            server.server_close()
            server_thread.join()

    def test_existing_rooms_survive_transient_failures_without_reseeding(self):
        state = MatrixState(
            {
                "!nav:test": "PerfNav",
                "!scroll-a:test": "PerfScrollA",
                "!scroll-b:test": "PerfScrollB",
            },
            invalid_login_once=True,
        )

        result = self.run_script(state, fail_joined_rooms_once=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(state.login_attempts, 2)
        self.assertEqual(state.joined_rooms_requests, 1)
        self.assertEqual(state.created_room_names, [])
        self.assertEqual(state.sent_messages, 0)
        self.assertIn("invalid_json", result.stderr)
        self.assertIn("HTTP 000", result.stderr)

    def test_new_rooms_are_created_and_seeded_once(self):
        state = MatrixState({})

        result = self.run_script(state)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertCountEqual(
            state.created_room_names,
            ["PerfNav", "PerfScrollA", "PerfScrollB"],
        )
        self.assertEqual(state.sent_messages, 3)


if __name__ == "__main__":
    unittest.main()
