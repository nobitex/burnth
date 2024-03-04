import subprocess
import json

p = subprocess.run(
    [
        "forge",
        "create",
        "--rpc-url",
        "http://127.0.0.1:8545",
        "--json",
        "--legacy",
        "--private-key",
        "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
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
        "http://127.0.0.1:8545",
        "--json",
        "--legacy",
        "--private-key",
        "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
        "src/WormCash.sol:WormCash",
        "--constructor-args",
        burnth_contract_addr,
    ],
    capture_output=True,
    text=True,
)

wormcash_contract_addr = json.loads(p.stdout)["deployedTo"]
print("WormCash:", wormcash_contract_addr)
