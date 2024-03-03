import json
import os
import ast
import io

from .field import Field


def get_mpt_path_proof(salt, lower, upper, is_top):
    MAX_BLOCKS = 4
    numLowerLayerBytes = len(lower)
    numUpperLayerBytes = len(upper)
    lowerLayer = list(lower) + (MAX_BLOCKS * 136 - len(lower)) * [0]
    upperLayer = list(upper) + (MAX_BLOCKS * 136 - len(upper)) * [0]

    with io.open("/tmp/input_mpt_path.json", "w") as f:
        json.dump(
            {
                "salt": salt,
                "numLowerLayerBytes": numLowerLayerBytes,
                "numUpperLayerBytes": 1 if is_top else numUpperLayerBytes,
                "lowerLayerBytes": lowerLayer,
                "upperLayerBytes": [0] * MAX_BLOCKS * 136 if is_top else upperLayer,
                "isTop": 1 if is_top else 0,
            },
            f,
        )

    os.system("cd zk && make gen_mpt_path_witness && make gen_mpt_path_proof")

    proof = open("/tmp/mpt_path_proof.json", "r").read()
    proof = ast.literal_eval(proof)
    proof = [
        [Field(int(s, 16)).val for s in proof[0]],
        [[Field(int(s, 16)).val for s in p] for p in proof[1]],
        [Field(int(s, 16)).val for s in proof[2]],
    ]

    output = open("/tmp/output_mpt_path.json", "r").read()
    output = ast.literal_eval(output)

    return proof, int(output[0])
