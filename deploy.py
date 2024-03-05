import subprocess
import json
import sys

RPC_URL = sys.argv[1]
PRIVATE_KEY = sys.argv[2]

print("Deploying contracts...")

p = subprocess.run(
    [
        "forge",
        "create",
        "--rpc-url",
        RPC_URL,
        "--json",
        "--legacy",
        "--private-key",
        PRIVATE_KEY,
        "src/Burnth.sol:Burnth",
    ],
    capture_output=True,
    text=True,
)

burnth_contract_addr = json.loads(p.stdout)["deployedTo"]
print("Burnth:", burnth_contract_addr)

p = subprocess.run(
    [
        "forge",
        "create",
        "--rpc-url",
        RPC_URL,
        "--json",
        "--legacy",
        "--private-key",
        PRIVATE_KEY,
        "src/WormCash.sol:WormCash",
        "--constructor-args",
        burnth_contract_addr,
    ],
    capture_output=True,
    text=True,
)

wormcash_contract_addr = json.loads(p.stdout)["deployedTo"]
print("WormCash:", wormcash_contract_addr)
