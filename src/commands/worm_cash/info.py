import json
from web3 import Web3


def load_abi(file_path):
    with open(file_path) as abi_file:
        return json.load(abi_file)


ABI_WORMCASH = load_abi("abis/WormCash.abi")
ABI_ERC20 = load_abi("abis/ERC20.abi")


class InfoContext:
    def __init__(self, amount_per_epoch, num_epochs, priv_src):
        self.amount_per_epoch = amount_per_epoch
        self.num_epochs = num_epochs
        self.priv_src = priv_src


def info_cmd(network, context):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    contract = w3.eth.contract(address=network.wormcash_contract_addr, abi=ABI_WORMCASH)
    address = w3.eth.account.from_key(context.priv_src).address
    balance = contract.functions.balanceOf(address).call()
    print("Your WormCash balance:", balance)

    if context.amount_per_epoch is not None and context.num_epochs is not None:
        currect_epoch = contract.functions.currentEpoch().call()
        print("currect epoch: ", currect_epoch)
        reward = contract.functions.rewardOf(currect_epoch).call()
        print("The approximate WRM you will be getting if you claim NOW: ", reward)
    else:
        print(
            "Provide optional `--amount-per-epoch` and `--num-epochs`  arguments to calculate your reward."
        )
