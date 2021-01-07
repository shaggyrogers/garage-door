#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
  server.py
  =========

  Description:           Basic HTTP server providing control over
                         the garage door opener.
  Author:                Michael De Pasquale
  Creation Date:         2021-01-06
  Modification Date:     2021-01-07

"""

from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from http import HTTPStatus
import json
import subprocess
import sys


# Listening address.
ADDRESS=('', 8080)


class GarageDoorRequestHandler(BaseHTTPRequestHandler):

    @staticmethod
    def _control(operation: str) -> subprocess.CompletedProcess:
        assert operation.isalnum()
        return subprocess.run(
            [
                "bash",
                "control.sh",
                operation
            ],
            capture_output=True,
            encoding='utf-8',
        )

    def do_GET(self) -> None:
        """ Passes a requested operation to control.sh and returns
            a JSON-encoded representation of the result.

            Path must be in the form '/{operation}' where operation
            is an argument accepted by control.sh.
        """
        # Parse request
        parts = list(filter(None, self.path.split('/')))

        if len(parts) != 1:
            self.send_error(
                HTTPStatus.BAD_REQUEST,
                "Invalid request, operation expected"
            )
            return

        operation = parts[0].lower()

        # No funny stuff
        if not operation.isalnum() or not operation.isascii():
            self.send_error(
                HTTPStatus.BAD_REQUEST,
                f"Invalid operation '{operation}'"
            )
            return

        # Control door
        proc = self._control(operation)
        self.log_message(f"control.sh returned {proc.returncode}")
        self.log_message(f"    operation={operation}")
        self.log_message(f"    stderr={proc.stderr}")
        self.log_message(f"    stdout={proc.stdout}")

        # Build response
        result = bytes(
            json.dumps(
                {
                    'operation': operation,
                    'success': proc.returncode == 0,
                    'returncode': proc.returncode,
                    'stdout': proc.stdout,
                    'stderr': proc.stderr,
                }
            ),
            encoding='utf-8'
        )

        self.send_response(
            HTTPStatus.OK if proc.returncode == 0
            else HTTPStatus.INTERNAL_SERVER_ERROR
        )
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(result)))
        self.end_headers()

        self.wfile.write(result)


def main(*args) -> int:
    """ Entry point. """
    # Initialise GPIO pins
    assert not GarageDoorRequestHandler._control('init').returncode

    # Start HTTP server
    srv = ThreadingHTTPServer(ADDRESS, GarageDoorRequestHandler)
    srv.serve_forever()

    return 0


if __name__ == '__main__':
    sys.exit(main(*sys.argv))

#  vim: set ts=8 sw=4 tw=79 fdm=marker et :
