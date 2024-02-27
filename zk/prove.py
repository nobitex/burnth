from web3 import Web3
import rlp

import mpt_last
import mpt_path
from field import Field
import mimc7

SALT = 123


def field_to_addr(f):
    f = f.val
    bts = []
    for i in range(20):
        bts.append(f % 256)
        f = f // 256
    
    return Web3.to_checksum_address('0x' + bytes(bts).hex())
BURN_PREIMAGE = Field(123456)
BURN_ADDRESS = field_to_addr(mimc7.mimc7(BURN_PREIMAGE, BURN_PREIMAGE))




def get_account_eth_mpt_proof(account, provider):
    w3 = Web3(Web3.HTTPProvider(provider))

    num = w3.eth.get_block_number()

    block = w3.eth.get_block(num)
    proof = w3.eth.get_proof(account, [], num)
    print(proof.nonce, proof.balance)

    for index, level in enumerate(proof.accountProof):
        if index == 0:
            if Web3.keccak(level) != block.stateRoot:
                raise Exception("Not verified!")
        if index >= 1:
            if Web3.keccak(level) not in proof.accountProof[index - 1]:
                raise Exception("Not verified!")
            print(
                mpt_path.get_mpt_path_proof(SALT, level, proof.accountProof[index - 1])
            )

    account_rlp = rlp.encode(
        [proof.nonce, proof.balance, proof.storageHash, proof.codeHash]
    )
    address_bytes = bytes.fromhex(str(proof.address)[2:])
    prefix_account_rlp = proof.accountProof[-1][: -len(account_rlp)]

    if Web3.keccak(prefix_account_rlp + account_rlp) not in proof.accountProof[-2]:
        raise Exception("Not verified!")

    print(
        mpt_last.get_last_proof(
            SALT,
            BURN_PREIMAGE.val,
            bytes(prefix_account_rlp),
            proof.nonce,
            proof.balance,
            proof.storageHash,
            proof.codeHash,
        )
    )


get_account_eth_mpt_proof(
    BURN_ADDRESS,
    "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
)
print("OK!")
