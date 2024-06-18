from zk.field import Field
from zk.mimc7 import mimc7
import os
import json
import io
import secrets
from hashlib import sha256
from web3 import Web3
import random


class BurnAddress:
    def __init__(self, preimage):
        hashed = mimc7(preimage, preimage).val
        bts = []
        for _ in range(20):
            bts.append(hashed % 256)
            hashed = hashed // 256
        self.preimage = preimage
        self.address = Web3.to_checksum_address("0x" + bytes(bts).hex())


class Coin:
    def __init__(self, amount: Field, salt: Field = None, encrypted: bool = True):
        self.amount = amount
        self.salt = salt
        self.encrypted = encrypted

    def get_value(self):
        if self.encrypted:
            return mimc7(self.amount, self.salt).val
        return self.amount.val

    @staticmethod
    def load_from_dict(d):
        return Coin(
            Field(int(d["amount"], 16)), Field(int(d["salt"], 16)), d["encrypted"]
        )

    def to_dict(self):
        return {
            "amount": hex(self.amount.val),
            "salt": hex(self.salt.val),
            "encrypted": self.encrypted,
        }


class Wallet:
    PATH = "burnth.priv"

    def __init__(self, entropy):
        self.entropy = entropy
        self.coins = self.load_coins()

    def load_coins(self):
        if not os.path.isfile(Wallet.PATH):
            return []
        with io.open(Wallet.PATH, "r") as f:
            return [Coin.load_from_dict(coin) for coin in json.load(f).get("coins", [])]

    def open_or_create():
        if not os.path.isfile(Wallet.PATH):
            wallet = {"entropy": bytes([secrets.randbits(8) for _ in range(32)]).hex()}
            with io.open(Wallet.PATH, "w") as f:
                json.dump(wallet, f)
        with io.open(Wallet.PATH, "r") as f:
            return Wallet(bytes.fromhex(json.load(f)["entropy"]))

    def derive_burn_addr(self, index: int) -> BurnAddress:
        sha_input = self.entropy + index.to_bytes(8, "little")
        preimage = Field(int.from_bytes(sha256(sha_input).digest()[:31], "little"))
        return BurnAddress(preimage)

    def derive_coin(self, amount: Field, encrypted: bool) -> Coin:
        salt = Field(random.randint(0, 2**256))
        return Coin(amount, salt, encrypted)

    def add_coin(self, coin: Coin):
        self.coins.append(coin)

    def remove_coin(self, index: int):
        self.coins.pop(index)

    def save(self):
        with io.open(Wallet.PATH, "w") as f:
            json.dump(
                {
                    "entropy": self.entropy.hex(),
                    "coins": [coin.to_dict() for coin in self.coins],
                },
                f,
            )
