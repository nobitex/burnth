import json
from web3 import Web3
from web3.exceptions import TransactionNotFound, TimeExhausted

from commands.utils import sign_and_send_transaction


def load_abi(file_path):
    with open(file_path) as abi_file:
        return json.load(abi_file)


ABI_WORMCASH = load_abi("abis/WormCash.abi")
ABI_ERC20 = load_abi("abis/ERC20.abi")


class ParticipateContext:
    def __init__(self, amount_per_epoch, num_epochs, priv_src):
        self.amount_per_epoch = amount_per_epoch
        self.num_epochs = num_epochs
        self.priv_src = priv_src


def participate_cmd(network, context):
    try:
        w3 = Web3(Web3.HTTPProvider(network.provider_url))
        amount_per_epoch = Web3.to_wei(context.amount_per_epoch, "ether")
        burnth_contract = w3.eth.contract(
            address=network.burnth_contract_addr, abi=ABI_ERC20
        )
        wormcash_contract = w3.eth.contract(
            address=network.wormcash_contract_addr, abi=ABI_WORMCASH
        )

        approx = Web3.from_wei(
            wormcash_contract.functions.approximate(
                amount_per_epoch, context.num_epochs
            ).call(),
            "ether",
        )
        ans = input(
            f"Consuming {context.amount_per_epoch * context.num_epochs} BURNTH. This will generate approximately {approx} WRM. Are you sure? (Y/n): "
        )

        if ans.lower() != "y":
            return

        address = w3.eth.account.from_key(context.priv_src).address
        gas_price = w3.eth.gas_price

        nonce = w3.eth.get_transaction_count(address)

        # Approve transaction
        approve_txn = burnth_contract.functions.approve(
            network.wormcash_contract_addr, amount_per_epoch * context.num_epochs
        ).build_transaction(
            {
                "chainId": network.chain_id,
                "gas": 7000000,
                "maxFeePerGas": gas_price,
                "maxPriorityFeePerGas": gas_price // 2,
                "nonce": nonce,
            }
        )
        print("Approve transaction ... ")
        sign_and_send_transaction(w3, approve_txn, context.priv_src)

        print("---------------------------------------- ")

        # Participate transaction
        nonce += 1
        participate_txn = wormcash_contract.functions.participate(
            amount_per_epoch, context.num_epochs
        ).build_transaction(
            {
                "chainId": network.chain_id,
                "gas": 7000000,
                "maxFeePerGas": gas_price,
                "maxPriorityFeePerGas": gas_price // 2,
                "nonce": nonce,
            }
        )
        print("Participate transaction ... ")
        sign_and_send_transaction(w3, participate_txn, context.priv_src)

    except Exception as e:
        print(f"An error occurred: {e}")
