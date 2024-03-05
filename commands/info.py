from web3 import Web3
from zk.models import Wallet
from zk.networks import Network


def info_cmd(network: Network):
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
