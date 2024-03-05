from web3 import Web3
from zk.networks import Network
from zk.field import Field
from zk.models import Wallet
from zk import spend

import json


class SpendContext:
    coin_index: int
    amount: float
    dst_addr: str
    priv_sender: str

    def __init__(self, coin_index: int, amount: float, dst_addr: str, priv_sender: str):
        self.coin_index = coin_index
        self.amount = amount
        self.dst_addr = dst_addr
        self.priv_sender = priv_sender


def spend_cmd(network: Network, context: SpendContext):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    wallet = Wallet.open_or_create()

    coin = wallet.coins[context.coin_index - 1]
    coin_balance = coin.amount.val
    widthdrawn_amount = Web3.to_wei(context.amount, "ether")
    remaining_balance = coin_balance - widthdrawn_amount
    remaining_coin = wallet.derive_coin(Field(remaining_balance), encrypted=True)
    proof = spend.get_spend_proof(coin.salt.val, coin_balance, widthdrawn_amount, remaining_coin.salt.val)

    contract_feed = [
        coin.get_value(),
        remaining_coin.get_value(),
        widthdrawn_amount,
        context.dst_addr,
        proof,
    ]

    contract = w3.eth.contract(address=network.burnth_contract_addr, abi=json.load(open("abis/Burnth.abi")))
    address = w3.eth.account.from_key(context.priv_sender).address
    nonce = w3.eth.get_transaction_count(address)
    gas_price = w3.eth.gas_price

    txn = contract.functions.spend(*contract_feed).build_transaction({
        'chainId': network.chain_id,
        'gas': 7000000,
        "maxFeePerGas": gas_price,
        "maxPriorityFeePerGas": gas_price // 2,
        'nonce': nonce,
    })

    signed = w3.eth.account.sign_transaction(txn, context.priv_sender)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)

    print("Waiting for the receipt...")
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print("Receipt:", receipt)

    if receipt.status == 0:
        raise Exception("Transaction failed")

    wallet.remove_coin(context.coin_index - 1)
    wallet.coins.append(remaining_coin)
    wallet.save()
    print("Transaction successful")
