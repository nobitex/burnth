.PHONY = build deploy_ganache abi

build:
	cd zk && make install

deploy:
	python3 deploy.py $(RPC_URL) $(PRIVATE_KEY)

abi:
	forge build --silent && jq '.abi' ./out/Burnth.sol/Burnth.json > abis/Burnth.abi
	forge build --silent && jq '.abi' ./out/WormCash.sol/WormCash.json > abis/WormCash.abi

RPC_URL ?= http://127.0.0.1:8545
PRIVATE_KEY ?= 0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d
