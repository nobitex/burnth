import json
import os
import ast
import io

from .field import Field


def get_mpt_path_proof(salt, layers, is_top):
    MAX_BLOCKS = 4
    MAX_LAYERS = 4

    num_layers = len(layers)

    while len(layers) < MAX_LAYERS:
        layers.append([])

    numLayerBytes = [len(l) for l in layers]
    layers = [list(l) + (MAX_BLOCKS * 136 - len(l)) * [0] for l in layers]

    with io.open("/tmp/input_mpt_path.json", "w") as f:
        json.dump(
            {
                "salt": str(salt),
                "numLayers": num_layers - 1,
                "numLayerBytes": numLayerBytes,
                "layerBytes": layers,
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
