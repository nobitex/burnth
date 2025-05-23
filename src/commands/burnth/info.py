from web3 import Web3
from zk.models import Wallet
from zk.networks import Network
import json


class InfoContext:
    priv_src: str

    def __init__(self, priv_src: str = None):
        self.priv_src = priv_src


def info_cmd(network: Network, context: InfoContext):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    wallet = Wallet.open_or_create()
    print("Your burn-addresses:")
    i = 0
    while True:
        burn_addr = wallet.derive_burn_addr(i).address
        balance = w3.eth.get_balance(burn_addr)
        eth = Web3.from_wei(balance, "ether")
        if eth == 0:
            break
        else:
            print(f"#{i+1}: {burn_addr} ({eth} ETH)")
            i += 1

    for idx, coin in enumerate(wallet.coins):
        if idx == 0:
            print("Your coins:")

        amount = Web3.from_wei(coin.amount.val, "ether")
        print(f"[IDX: {idx+1}] Amount: {amount} ETH | Salt: {coin.salt.val}")

    if context.priv_src:
        contract = w3.eth.contract(
            address=network.burnth_contract_addr, abi=json.load(open("abis/Burnth.abi"))
        )
        address = w3.eth.account.from_key(context.priv_src).address
        print(
            "Your BURNTH balance:",
            Web3.from_wei(contract.functions.balanceOf(address).call(), "ether"),
        )
