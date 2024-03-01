import json, io, ast
from field import Field
from mimc7 import mimc7
import os

security = 20
maxBlocks = 4
maxLowerLen = 99
maxPrefixLen = maxBlocks * 136 - maxLowerLen


def get_last_proof(
    salt, encrypted, lowerLayerPrefix, nonce, balance, storageHash, codeHash, burnPreimage
):
    lowerLayerPrefixLen = len(lowerLayerPrefix)
    lowerLayerPrefix += (maxPrefixLen - len(lowerLayerPrefix)) * b"\x00"

    with io.open("/tmp/input_mpt_last.json", "w") as f:
        json.dump(
            {
                "salt": salt,
                "encrypted": 1 if encrypted else 0,
                "nonce": int(nonce),
                "balance": int(balance),
                "storageHash": list(storageHash),
                "codeHash": list(codeHash),
                "lowerLayerPrefix": list(lowerLayerPrefix),
                "lowerLayerPrefixLen": lowerLayerPrefixLen,
                "burn_preimage": burnPreimage,
            },
            f,
        )

    os.system(
        "cd zk && make gen_mpt_last_witness && make gen_mpt_last_proof"
    )

    proof = open("/tmp/mpt_last_proof.json", "r").read()
    proof = ast.literal_eval(proof)    
    proof = [
        [Field(int(s, 16)).val for s in proof[0]],
        [[Field(int(s, 16)).val for s in p] for p in proof[1]],
        [Field(int(s, 16)).val for s in proof[2]],
    ]
        
    return proof
