import json, io
import os

security = 20
maxBlocks = 4
maxLowerLen = 99
maxPrefixLen = maxBlocks * 136 - maxLowerLen


def get_last_proof(
    salt,
    burnPreimage,
    lowerLayerPrefix,
    nonce,
    balance,
    storageHash,
    codeHash,
    encrypted,
):
    lowerLayerPrefixLen = len(lowerLayerPrefix)
    lowerLayerPrefix += (maxPrefixLen - len(lowerLayerPrefix)) * b"\x00"

    with io.open("circuit/input.json", "w") as f:
        json.dump(
            {
                "salt": salt,
                "burn_preimage": str(burnPreimage),
                "nonce": str(nonce),
                "balance": str(balance),
                "storageHash": list(storageHash),
                "codeHash": list(codeHash),
                "lowerLayerPrefix": list(lowerLayerPrefix),
                "lowerLayerPrefixLen": lowerLayerPrefixLen,
                "encrypted": 1 if encrypted else 0,
            },
            f,
        )

    os.system(
        "cd circuit/mpt_last_cpp && ./mpt_last ../input.json ../mpt_last_witness.wtns"
    )

    with io.open("circuit/mpt_last_cpp/output.json", "r") as f:
        return [int(s) for s in json.loads(f.read())]
