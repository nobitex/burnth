.PHONY = build deploy_ganache abi

build:
	cd zk && make install

deploy_ganache:
	python3 deploy_ganache.py

abi:
	forge build --silent && jq '.abi' ./out/Burnth.sol/Burnth.json > abis/Burnth.abi
	forge build --silent && jq '.abi' ./out/WormCash.sol/WormCash.json > abis/WormCash.abi