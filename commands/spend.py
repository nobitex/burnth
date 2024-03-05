from web3 import Web3
from zk.networks import Network
from zk.field import Field
from zk.mimc7 import mimc7
from zk import spend

import json

SALT = 1234

class SpendContext:
    coin_balance: float
    amount: float
    dst_addr: str
    priv_sender: str

    def __init__(self, coin_balance: float, amount: float, dst_addr: str, priv_sender: str):
        self.coin_balance = coin_balance
        self.amount = amount
        self.dst_addr = dst_addr
        self.priv_sender = priv_sender


def spend_cmd(network: Network, context: SpendContext):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))

    coin_balance = Web3.to_wei(context.coin_balance, "ether")
    coin = mimc7(Field(coin_balance), Field(SALT)).val
    widthdrawn_amount = Web3.to_wei(context.amount, "ether")
    remaining_balance = coin_balance - widthdrawn_amount
    remaining_coin = mimc7(Field(remaining_balance), Field(SALT)).val
    proof = spend.get_spend_proof(SALT, coin_balance, widthdrawn_amount)

    contract_feed = [
        coin,
        remaining_coin,
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
