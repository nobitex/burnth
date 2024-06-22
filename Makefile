.PHONY = build deploy abi

rapidsnark/package/bin/prover:
	cd rapidsnark && git submodule init
	cd rapidsnark && git submodule update
	cd rapidsnark && ./build_gmp.sh host
	cd rapidsnark && mkdir -p build_prover
	cd rapidsnark && cd build_prover && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
	cd rapidsnark && cd build_prover && make -j4 && make install

build:
	cd src/zk && make install

deploy:
	python3 script/deploy.py $(RPC_URL) $(PRIVATE_KEY) $(NETWORK)

abi:
	forge build --silent && jq '.abi' ./out/Burnth.sol/Burnth.json > abis/Burnth.abi
	forge build --silent && jq '.abi' ./out/WormCash.sol/WormCash.json > abis/WormCash.abi

delete_wallet:
	rm -rf burnth.priv

RPC_URL ?= http://127.0.0.1:8545
NETWORK ?= ganache
PRIVATE_KEY ?= 0xb8ae44cf180f22750913a170f6280e2d082afc6387b83bd1d307d207c1988447
