.PHONY = gen_mpt_path_witness gen_mpt_path_proof gen_mpt_path_solidity gen_mpt_last_witness gen_mpt_last_proof gen_mpt_last_solidity gen_spend_witness gen_spend_proof gen_spend_solidity

circuit/pot_final.ptau:
	cd circuit && snarkjs powersoftau new bn128 21 pot_0000.ptau -v
	cd circuit && snarkjs powersoftau contribute pot_0000.ptau pot_0001.ptau --entropy=1234 --name="first contribution" -v
	cd circuit && snarkjs powersoftau prepare phase2 pot_0001.ptau pot_final.ptau -v

circuit/out/mpt_path_cpp/mpt_path: circuit/mpt_path.circom circuit/utils/*.circom
ifeq ($(DEVELOPMENT), true)
	cd circuit && circom mpt_path.circom --r1cs --wasm --sym --c --output out/

	mv circuit/out/mpt_path_cpp/main.cpp circuit/out/mpt_path_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/out/mpt_path_cpp/main.cpp.tmp > circuit/out/mpt_path_cpp/main.cpp
	rm circuit/out/mpt_path_cpp/main.cpp.tmp
endif

	cd circuit/out/mpt_path_cpp && make

circuit/mpt_path_0001.zkey: circuit/out/mpt_path_cpp/mpt_path
ifeq ($(DOWNLOAD_ZKEY_FROM_GIT), false)
	cd circuit && snarkjs groth16 setup out/mpt_path.r1cs pot_final.ptau mpt_path_0000.zkey
	cd circuit && snarkjs zkey contribute mpt_path_0000.zkey mpt_path_0001.zkey --entropy=1234 --name="second contribution" -v
else
	cd circuit && wget -c https://github.com/nobitex/burnth/releases/download/$(REALEASE_VERSION)/mpt_path_0001.zkey -O mpt_path_0001.zkey
	cd circuit && snarkjs zkey export verificationkey mpt_path_0001.zkey verification_key.json
endif

gen_mpt_path_witness:
	cd circuit && ./out/mpt_path_cpp/mpt_path /tmp/input_mpt_path.json mpt_path_witness.wtns
	mv circuit/output.json /tmp/output_mpt_path.json

gen_mpt_path_proof:
	cd circuit && ../../rapidsnark/package/bin/prover mpt_path_0001.zkey mpt_path_witness.wtns mpt_path_proof.json mpt_path_public.json
	snarkjs generatecall circuit/mpt_path_public.json circuit/mpt_path_proof.json > /tmp/mpt_path_proof.json 

gen_mpt_path_solidity: circuit/mpt_path_0001.zkey
	cd circuit && snarkjs zkey export solidityverifier mpt_path_0001.zkey ../../src/MptMiddleVerifier.sol
	sed -i 's/Groth16Verifier/MptMiddleVerifier/' ../src/MptMiddleVerifier.sol

circuit/out/mpt_last_cpp/mpt_last: circuit/mpt_last.circom circuit/utils/*.circom
ifeq ($(DEVELOPMENT), true)
	cd circuit && circom mpt_last.circom --r1cs --wasm --sym --c --output out/

	mv circuit/out/mpt_last_cpp/main.cpp circuit/out/mpt_last_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/out/mpt_last_cpp/main.cpp.tmp > circuit/out/mpt_last_cpp/main.cpp
	rm circuit/out/mpt_last_cpp/main.cpp.tmp
endif

	cd circuit/out/mpt_last_cpp && make

circuit/mpt_last_0001.zkey: circuit/out/mpt_last_cpp/mpt_last
ifeq ($(DOWNLOAD_ZKEY_FROM_GIT), false)
	cd circuit && snarkjs groth16 setup out/mpt_last.r1cs pot_final.ptau mpt_last_0000.zkey
	cd circuit && snarkjs zkey contribute mpt_last_0000.zkey mpt_last_0001.zkey --entropy=1234 --name="second contribution" -v
else
	cd circuit && wget -c https://github.com/nobitex/burnth/releases/download/$(REALEASE_VERSION)/mpt_last_0001.zkey -O mpt_last_0001.zkey
	cd circuit && snarkjs zkey export verificationkey mpt_last_0001.zkey verification_key.json
endif

gen_mpt_last_witness:
	cd circuit && ./out/mpt_last_cpp/mpt_last /tmp/input_mpt_last.json mpt_last_witness.wtns
	mv circuit/output.json /tmp/output_mpt_last.json

gen_mpt_last_proof:
	cd circuit && ../../rapidsnark/package/bin/prover mpt_last_0001.zkey mpt_last_witness.wtns mpt_last_proof.json mpt_last_public.json
	snarkjs generatecall circuit/mpt_last_public.json circuit/mpt_last_proof.json > /tmp/mpt_last_proof.json 

gen_mpt_last_solidity: circuit/mpt_last_0001.zkey
	cd circuit && snarkjs zkey export solidityverifier mpt_last_0001.zkey ../../src/MptLastVerifier.sol
	sed -i 's/Groth16Verifier/MptLastVerifier/' ../src/MptLastVerifier.sol

circuit/out/spend_cpp/spend: circuit/spend.circom circuit/utils/*.circom
ifeq ($(DEVELOPMENT), true)
	cd circuit && circom spend.circom --r1cs --wasm --sym --c --output out/

	mv circuit/out/spend_cpp/main.cpp circuit/out/spend_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/out/spend_cpp/main.cpp.tmp > circuit/out/spend_cpp/main.cpp
	rm circuit/out/spend_cpp/main.cpp.tmp
endif

	cd circuit/out/spend_cpp && make

circuit/spend_0001.zkey: circuit/out/spend_cpp/spend
ifeq ($(DOWNLOAD_ZKEY_FROM_GIT), false)
	cd circuit && snarkjs groth16 setup out/spend.r1cs pot_final.ptau spend_0000.zkey
	cd circuit && snarkjs zkey contribute spend_0000.zkey spend_0001.zkey --entropy=1234 --name="second contribution" -v
else
	cd circuit && wget -c https://github.com/nobitex/burnth/releases/download/$(REALEASE_VERSION)/spend_0001.zkey -O spend_0001.zkey
	cd circuit && snarkjs zkey export verificationkey spend_0001.zkey verification_key.json
endif

gen_spend_witness: circuit/out/spend_cpp/spend
	cd circuit && ./out/spend_cpp/spend /tmp/input_spend.json spend_witness.wtns
	mv circuit/output.json /tmp/output_spend.json

gen_spend_proof:
	cd circuit && ../../rapidsnark/package/bin/prover spend_0001.zkey spend_witness.wtns spend_proof.json spend_public.json
	snarkjs generatecall circuit/spend_public.json circuit/spend_proof.json > /tmp/spend_proof.json 

gen_spend_solidity: circuit/spend_0001.zkey
	cd circuit && snarkjs zkey export solidityverifier spend_0001.zkey ../../src/SpendVerifier.sol
	sed -i 's/Groth16Verifier/SpendVerifier/' ../src/SpendVerifier.sol

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} +
	rm -rf circuit/out/*.r1cs circuit/out/*.wasm circuit/out/*.sym circuit/*.json circuit/out/*.wtns circuit/mpt_path_cpp/ circuit/out/mpt_path_js/ circuit/mpt_last_cpp/ circuit/out/mpt_last_js/ circuit/spend_cpp/ circuit/out/spend_js/
	rm -rf ../src/MptMiddleVerifier.sol ../src/MptLastVerifier.sol ../src/SpendVerifier.sol

clean_all: clean
	rm -rf circuit/*.zkey circuit/out/*

install: gen_mpt_path_solidity gen_mpt_last_solidity gen_spend_solidity

DOWNLOAD_ZKEY_FROM_GIT ?= true
REALEASE_VERSION ?= v0.1.0-sepolia
DEVELOPMENT ?= false