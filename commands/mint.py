from web3 import Web3
from zk.models import Wallet
from zk.networks import Network
from zk.field import Field
from zk.mimc7 import mimc7
from zk.utils import get_block_splited_information, get_proof_of_burn

import json

class MintContext:
    src_burn_addr: str
    dst_addr: str
    encrypted: bool
    priv_fee_payer: str

    def __init__(self, src_burn_addr: str, dst_addr: str, encrypted: bool, priv_fee_payer: str):
        self.src_burn_addr = src_burn_addr
        self.dst_addr = dst_addr
        self.encrypted = encrypted
        self.priv_fee_payer = priv_fee_payer


def mint_cmd(network: Network, context: MintContext):
    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    wallet = Wallet.open_or_create()
    burn_addr = None
    for i in range(10):
        if context.src_burn_addr == str(wallet.derive_burn_addr(i).address):
            burn_addr = wallet.derive_burn_addr(i)
            amount = w3.eth.get_balance(burn_addr.address)
            break

    if not burn_addr:
        raise Exception("Burn address not found!")

    block_number = w3.eth.get_block_number()
    coin = wallet.derive_coin(Field(amount), context.encrypted)
    nullifier = mimc7(burn_addr.preimage, Field(0)).val
    layers = []

    w3 = Web3(Web3.HTTPProvider(network.provider_url))
    block = w3.eth.get_block(block_number)
    proof = w3.eth.get_proof(burn_addr.address, [], block_number)

    (prefix, state_root, postfix) = get_block_splited_information(block)
    (layers, root_proof, mid_proofs, last_proof) = get_proof_of_burn(burn_addr, coin.salt.val, context.encrypted, block, proof)

    target = context.dst_addr

    contract_feed = [
        block_number,
        coin.get_value(),
        nullifier,
        layers,
        root_proof,
        mid_proofs,
        last_proof,
        context.encrypted,
        target,
        prefix,
        state_root,
        postfix,
    ]

    contract = w3.eth.contract(address=network.burnth_contract_addr, abi=json.load(open("abis/Burnth.abi")))
    address = w3.eth.account.from_key(context.priv_fee_payer).address
    nonce = w3.eth.get_transaction_count(address)
    gas_price = w3.eth.gas_price

    txn = contract.functions.mint(contract_feed).build_transaction({
        'chainId': network.chain_id,
        'gas': 7000000,
        "maxFeePerGas": gas_price,
        "maxPriorityFeePerGas": gas_price // 2,
        'nonce': nonce,
    })

    signed = w3.eth.account.sign_transaction(txn, context.priv_fee_payer)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)

    print("Waiting for the receipt...")
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print("Receipt:", receipt)

    if receipt.status == 0:
        raise Exception("Transaction failed!")

    # TODO: if save failed, the coin will be lost. Need to fix this.
    wallet.add_coin(coin)
    wallet.save()
    print("Minted successfully!")
