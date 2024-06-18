import subprocess
import json
import sys
import re

RPC_URL = sys.argv[1]
PRIVATE_KEY = sys.argv[2]
NETWORK_NAME = sys.argv[3]


print("Deploying contracts...")


def update_networks_file(network_name, burnth_address, wormcash_address):
    with open("src/zk/networks.py", "r") as file:
        lines = file.readlines()

    found = False
    for i, line in enumerate(lines):
        if f'"{network_name}": Network(' in line:
            found = True
            while not lines[i].strip().endswith("),"):
                if "0x" in lines[i]:
                    if "burnth_contract_addr" not in locals():
                        lines[i] = f'        "{burnth_address}",\n'
                        burnth_contract_addr = True
                    else:
                        lines[i] = f'        "{wormcash_address}",\n'
                i += 1
            # Update the last address line (wormcash_contract_addr)
            if "0x" in lines[i]:
                lines[i] = f'        "{wormcash_address}",\n'

    if not found:
        print(f"Network {network_name} not found in networks.py")

    with open("src/zk/networks.py", "w") as file:
        file.writelines(lines)
        print("Successfully updated networks.py")


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
        "src/contracts/Burnth.sol:Burnth",
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
        "src/contracts/WormCash.sol:WormCash",
        "--constructor-args",
        burnth_contract_addr,
    ],
    capture_output=True,
    text=True,
)

wormcash_contract_addr = json.loads(p.stdout)["deployedTo"]
print("WormCash:", wormcash_contract_addr)

update_networks_file(NETWORK_NAME, burnth_contract_addr, wormcash_contract_addr)
