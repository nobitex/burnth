from web3 import Web3
from zk.models import Wallet
from zk.networks import Network

from commands.utils import sign_and_send_transaction


class BurnContext:
    amount: float
    priv_src: str

    def __init__(self, amount: float, priv_src: str):
        self.amount = amount
        self.priv_src = priv_src


def burn_cmd(network: Network, context: BurnContext):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    wallet = Wallet.open_or_create()

    for i in range(10):
        burn_addr = wallet.derive_burn_addr(i).address
        balance = w3.eth.get_balance(burn_addr)
        if balance == 0:
            break
    ans = input(
        f"Burning {context.amount} ETH by sending them to {burn_addr}. Are you sure? (Y/n): "
    )
    if ans.lower() == "y":
        gas_price = w3.eth.gas_price
        amount_wei = Web3.to_wei(context.amount, "ether")
        acc = w3.eth.account.from_key(context.priv_src)
        transaction = {
            "from": acc.address,
            "to": burn_addr,
            "value": amount_wei,
            "nonce": w3.eth.get_transaction_count(acc.address),
            "gas": 21000,
            "maxFeePerGas": gas_price,
            "maxPriorityFeePerGas": gas_price // 2,
            "chainId": network.chain_id,
        }
        sign_and_send_transaction(w3, transaction, context.priv_src)
