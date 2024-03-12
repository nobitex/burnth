.PHONY = build deploy abi

rapidsnark/package/bin/prover:
	cd rapidsnark && git submodule init
	cd rapidsnark && git submodule update
	cd rapidsnark && ./build_gmp.sh host
	cd rapidsnark && mkdir -p build_prover
	cd rapidsnark && cd build_prover && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../package
	cd rapidsnark && cd build_prover && make -j4 && make install

build:
	cd zk && make install

deploy:
	python3 deploy.py $(RPC_URL) $(PRIVATE_KEY)

abi:
	forge build --silent && jq '.abi' ./out/Burnth.sol/Burnth.json > abis/Burnth.abi
	forge build --silent && jq '.abi' ./out/WormCash.sol/WormCash.json > abis/WormCash.abi


RPC_URL ?= http://127.0.0.1:8545
PRIVATE_KEY ?= 0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d
