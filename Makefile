.PHONY = install abi

install:
	cd zk && make install

abi:
	forge build --silent && jq '.abi' ./out/Burnth.sol/Burnth.json > abis/Burnth.abi
	forge build --silent && jq '.abi' ./out/WormCash.sol/WormCash.json > abis/WormCash.abi