import json
from web3 import Web3
from commands.utils import sign_and_send_transaction


def load_abi(file_path):
    with open(file_path) as abi_file:
        return json.load(abi_file)


ABI_WORMCASH = load_abi("abis/WormCash.abi")
ABI_ERC20 = load_abi("abis/ERC20.abi")


class ClaimContext:
    def __init__(self, starting_epoch, num_epochs, priv_src):
        self.starting_epoch = starting_epoch
        self.num_epochs = num_epochs
        self.priv_src = priv_src


def claim_cmd(network, context):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    contract = w3.eth.contract(address=network.wormcash_contract_addr, abi=ABI_WORMCASH)
    current_epoch = contract.functions.currentEpoch().call()
    print("currect epoch: ", current_epoch)
    ans = input(f"Claiming WRM of {context.num_epochs} epochs. Are you sure? (Y/n): ")   

    if ans.lower() == "y":
        address = w3.eth.account.from_key(context.priv_src).address
        nonce = w3.eth.get_transaction_count(address)
        gas_price = w3.eth.gas_price

        claim_txn = contract.functions.claim(
            context.starting_epoch, context.num_epochs
        ).build_transaction(
            {
                "chainId": network.chain_id,
                "gas": 7000000,
                "maxFeePerGas": gas_price,
                "maxPriorityFeePerGas": gas_price // 2,
                "nonce": nonce,
            }
        )
        sign_and_send_transaction(w3, claim_txn, context.priv_src)
