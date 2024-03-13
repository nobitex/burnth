import json
from web3 import Web3
from zk.models import Wallet
from zk.networks import Network
from functools import partial

from http.server import BaseHTTPRequestHandler, HTTPServer
import io
import pathlib

PATH = pathlib.Path(__file__).parent.resolve()

hostName = "localhost"
serverPort = 8080


class UiServer(BaseHTTPRequestHandler):
    def __init__(self, w3, wallet, *args, **kwargs) -> None:
        self.w3 = w3
        self.wallet = wallet
        super().__init__(*args, **kwargs)

    def do_GET(self):
        self.send_response(200)

        if self.path == "/burn":
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            for i in range(10):
                burn_addr = self.wallet.derive_burn_addr(i).address
                balance = self.w3.eth.get_balance(burn_addr)
                if balance == 0:
                    break
            self.wfile.write(
                json.dumps({"burn_address": str(burn_addr)}).encode("utf-8")
            )
            return
        else:
            self.end_headers()
            path = "index.html" if self.path == "/" else self.path[1:]
            with io.open(PATH.joinpath("assets").joinpath(path), "rb") as f:
                self.wfile.write(f.read())


def ui_cmd(network: Network):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    wallet = Wallet.open_or_create()

    webServer = HTTPServer((hostName, serverPort), partial(UiServer, w3, wallet))
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
