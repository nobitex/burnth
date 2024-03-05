from zk.field import Field
from zk.mimc7 import mimc7
import os
import json
import io
import secrets
from hashlib import sha256
from web3 import Web3


class BurnAddress:
    def __init__(self, preimage):
        hashed = mimc7(preimage, preimage).val
        bts = []
        for _ in range(20):
            bts.append(hashed % 256)
            hashed = hashed // 256
        self.preimage = preimage
        self.address = Web3.to_checksum_address("0x" + bytes(bts).hex())


class Wallet:
    def __init__(self, entropy):
        self.entropy = entropy

    def open_or_create():
        path = "burnth.priv"
        if not os.path.isfile(path):
            wallet = {"entropy": bytes([secrets.randbits(8) for _ in range(32)]).hex()}
            with io.open(path, "w") as f:
                json.dump(wallet, f)
        with io.open(path, "r") as f:
            return Wallet(bytes.fromhex(json.load(f)["entropy"]))

    def derive_burn_addr(self, index: int) -> BurnAddress:
        sha_input = self.entropy + index.to_bytes(8, "little")
        preimage = Field(int.from_bytes(sha256(sha_input).digest()[:31], "little"))
        return BurnAddress(preimage)
