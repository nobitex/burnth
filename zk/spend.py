import json
import os
import io
import ast
from .field import Field


def get_spend_proof(salt, balance, withdrawnBalance):
    with io.open("/tmp/input_spend.json", "w") as f:
        json.dump(
            {
                "balance": str(balance),
                "salt": str(salt),
                "withdrawnBalance": str(withdrawnBalance),
            },
            f,
        )

    os.system("cd zk && make gen_spend_witness && make gen_spend_proof")

    proof = open("/tmp/spend_proof.json", "r").read()
    proof = ast.literal_eval(proof)
    proof = [
        [Field(int(s, 16)).val for s in proof[0]],
        [[Field(int(s, 16)).val for s in p] for p in proof[1]],
        [Field(int(s, 16)).val for s in proof[2]],
    ]

    return proof
