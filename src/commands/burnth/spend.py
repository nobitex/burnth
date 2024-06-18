from web3 import Web3
from zk.networks import Network
from zk.field import Field
from zk.models import Wallet
from zk import spend
from commands.utils import sign_and_send_transaction
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
    try:
        w3 = Web3(Web3.HTTPProvider(network.provider_url))
        wallet = Wallet.open_or_create()

        if context.coin_index - 1 >= len(wallet.coins):
            raise IndexError("Invalid coin index")

        coin = wallet.coins[context.coin_index - 1]
        coin_balance = coin.amount.val
        widthdrawn_amount = Web3.to_wei(context.amount, "ether")

        if widthdrawn_amount > coin_balance:
            raise ValueError("Insufficient balance")

        remaining_balance = coin_balance - widthdrawn_amount
        remaining_coin = wallet.derive_coin(Field(remaining_balance), encrypted=True)

        proof = spend.get_spend_proof(
            coin.salt.val, coin_balance, widthdrawn_amount, remaining_coin.salt.val
        )

        contract_feed = [
            coin.get_value(),
            remaining_coin.get_value(),
            widthdrawn_amount,
            context.dst_addr,
            proof,
        ]

        try:
            with open("abis/Burnth.abi", "r") as abi_file:
                contract_abi = json.load(abi_file)
        except FileNotFoundError:
            raise FileNotFoundError("ABI file not found")

        contract = w3.eth.contract(
            address=network.burnth_contract_addr, abi=contract_abi
        )

        address = w3.eth.account.from_key(context.priv_sender).address
        nonce = w3.eth.get_transaction_count(address)
        gas_price = w3.eth.gas_price

        txn = contract.functions.spend(*contract_feed).build_transaction(
            {
                "chainId": network.chain_id,
                "gas": 7000000,
                "maxFeePerGas": gas_price,
                "maxPriorityFeePerGas": gas_price // 2,
                "nonce": nonce,
            }
        )

        sign_and_send_transaction(w3, txn, context.priv_sender)

        wallet.remove_coin(context.coin_index - 1)
        wallet.coins.append(remaining_coin)
        wallet.save()
        print("Transaction successful")
        print(contract.address)
        print(
            "Your BURNTH balance:",
            Web3.from_wei(
                contract.functions.balanceOf(context.dst_addr).call(), "ether"
            ),
        )

    except Exception as e:
        print(f"Error: {str(e)}")
