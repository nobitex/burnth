from zk import mpt_last, mpt_path
from zk.models import BurnAddress

from hexbytes.main import HexBytes
from web3 import Web3
import rlp


def get_block_splited_information(block):
    hashes = [
        block.parentHash.hex(),
        block.sha3Uncles.hex(),
        block.miner,
        block.stateRoot.hex(),
        block.transactionsRoot.hex(),
        block.receiptsRoot.hex(),
        block.logsBloom.hex(),
        hex(block.difficulty),
        hex(block.number),
        hex(block.gasLimit),
        hex(block.gasUsed),
        hex(block.timestamp),
        block.extraData.hex(),
        block.mixHash.hex(),
        block.nonce.hex(),
    ]

    optional_headers = [
        "baseFeePerGas",
        "withdrawalsRoot",
        "blobGasUsed",
        "excessBlobGas",
        "parentBeaconBlockRoot",
    ]

    for header in optional_headers:
        if hasattr(block, header):
            v = getattr(block, header)
            if isinstance(v, HexBytes):
                hashes.append(v.hex())
            elif isinstance(v, int):
                hashes.append(hex(v))
            else:
                hashes.append(v)

    hashes = ["0x" if h == "0x0" else h for h in hashes]
    header = rlp.encode([Web3.to_bytes(hexstr=h) for h in hashes])
    assert Web3.keccak(header) == block.hash

    start_idx = header.index(bytes(block.stateRoot))
    end_idx = start_idx + len(bytes(block.stateRoot))
    prefix = header[:start_idx]
    postfix = header[end_idx:]
    commit_top = header[start_idx:end_idx]

    return prefix, commit_top, postfix


def get_proof_of_burn(burn_address: BurnAddress, salt, encrypted, block, proof):
    account_rlp = rlp.encode(
        [proof.nonce, proof.balance, proof.storageHash, proof.codeHash]
    )
    prefix_account_rlp = proof.accountProof[-1][: -len(account_rlp)]

    if Web3.keccak(prefix_account_rlp + account_rlp) not in proof.accountProof[-2]:
        raise Exception("Not verified!")

    layers = []

    last_proof, last_proof_upper_commit = mpt_last.get_last_proof(
        salt,
        encrypted,
        bytes(prefix_account_rlp),
        proof.nonce,
        proof.balance,
        proof.storageHash,
        proof.codeHash,
        burn_address.preimage.val,
    )
    layers.append(last_proof_upper_commit)

    root_proof = None
    path_proofs = []
    rev_proof = proof.accountProof[::-1]
    for index, level in enumerate(rev_proof):
        if index == len(rev_proof) - 1:
            if Web3.keccak(level) != block.stateRoot:
                raise Exception("Not verified!")
            root_proof, _ = mpt_path.get_mpt_path_proof(
                salt, level, block.stateRoot, True
            )
        else:
            if Web3.keccak(level) not in rev_proof[index + 1]:
                raise Exception("Not verified!")
            mpt_path_proof, mpt_path_upper_commit = mpt_path.get_mpt_path_proof(
                salt, level, rev_proof[index + 1], False
            )
            path_proofs.append(mpt_path_proof)
            layers.append(mpt_path_upper_commit)

    return layers, root_proof, path_proofs, last_proof
