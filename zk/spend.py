import json
import os
import io


def get_spend_proof(salt, balance, withdrawnBalance):
    with io.open("circuit/input.json", "w") as f:
        json.dump(
            {
                "balance": str(balance),
                "salt": str(salt),
                "withdrawnBalance": str(withdrawnBalance),
            },
            f,
        )

    os.system("cd circuit/spend_cpp && ./spend ../input.json ../spend_witness.wtns")
    with io.open("circuit/spend_cpp/output.json", "r") as f:
        return [int(s) for s in json.loads(f.read())]
