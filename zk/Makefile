.PHONY = all

trusted_setup:
	cd circuit && snarkjs powersoftau new bn128 21 pot12_0000.ptau -v
	cd circuit && snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --entropy=1234 --name="first contribution" -v
	cd circuit && snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v

mpt_first:
	cd circuit && circom mpt_first.circom --r1cs --wasm --sym --c

	mv circuit/mpt_first_cpp/main.cpp circuit/mpt_first_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/mpt_first_cpp/main.cpp.tmp > circuit/mpt_first_cpp/main.cpp
	rm circuit/mpt_first_cpp/main.cpp.tmp
	cd circuit/mpt_first_cpp && make

mpt_first_zkey: mpt_first
	cd circuit && snarkjs groth16 setup mpt_first.r1cs pot12_final.ptau mpt_first_0000.zkey
	cd circuit && snarkjs zkey contribute mpt_first_0000.zkey mpt_first_0001.zkey --entropy=1234 --name="second contribution" -v
	cd circuit && snarkjs zkey export verificationkey mpt_first_0001.zkey verification_key.json

gen_mpt_first_witness:
	cd circuit && ./mpt_first_cpp/mpt_first /tmp/input_mpt_first.json mpt_first_witness.wtns
	mv circuit/output.json /tmp/output_mpt_first.json

gen_mpt_first_proof:
	cd circuit && snarkjs groth16 prove mpt_first_0001.zkey mpt_first_witness.wtns mpt_first_proof.json mpt_first_public.json
	snarkjs generatecall circuit/mpt_first_public.json circuit/mpt_first_proof.json > /tmp/mpt_first_proof.json 

gen_mpt_first_solidity: mpt_first_zkey
	cd circuit && snarkjs zkey export solidityverifier mpt_first_0001.zkey ../../src/MptFirstVerifier.sol
	sed -i 's/Groth16Verifier/MptFirstVerifier/' ../src/MptFirstVerifier.sol

mpt_path:
	cd circuit && circom mpt_path.circom --r1cs --wasm --sym --c

	mv circuit/mpt_path_cpp/main.cpp circuit/mpt_path_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/mpt_path_cpp/main.cpp.tmp > circuit/mpt_path_cpp/main.cpp
	rm circuit/mpt_path_cpp/main.cpp.tmp
	cd circuit/mpt_path_cpp && make

mpt_path_zkey: mpt_path
	cd circuit && snarkjs groth16 setup mpt_path.r1cs pot12_final.ptau mpt_path_0000.zkey
	cd circuit && snarkjs zkey contribute mpt_path_0000.zkey mpt_path_0001.zkey --entropy=1234 --name="second contribution" -v
	cd circuit && snarkjs zkey export verificationkey mpt_path_0001.zkey verification_key.json

gen_mpt_path_witness:
	cd circuit && ./mpt_path_cpp/mpt_path /tmp/input_mpt_path.json mpt_path_witness.wtns
	mv circuit/output.json /tmp/output_mpt_path.json

gen_mpt_path_proof:
	cd circuit && snarkjs groth16 prove mpt_path_0001.zkey mpt_path_witness.wtns mpt_path_proof.json mpt_path_public.json
	mv circuit/mpt_path_public.json /tmp/mpt_path_public.json

gen_mpt_path_solidity: mpt_path_zkey
	cd circuit && snarkjs zkey export solidityverifier mpt_path_0001.zkey ../../src/MptMiddleVerifier.sol
	sed -i 's/Groth16Verifier/MptMiddleVerifier/' ../src/MptMiddleVerifier.sol

mpt_last:
	cd circuit && circom mpt_last.circom --r1cs --wasm --sym --c

	mv circuit/mpt_last_cpp/main.cpp circuit/mpt_last_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/mpt_last_cpp/main.cpp.tmp > circuit/mpt_last_cpp/main.cpp
	rm circuit/mpt_last_cpp/main.cpp.tmp
	cd circuit/mpt_last_cpp && make

mpt_last_zkey: mpt_last
	cd circuit && snarkjs groth16 setup mpt_last.r1cs pot12_final.ptau mpt_last_0000.zkey
	cd circuit && snarkjs zkey contribute mpt_last_0000.zkey mpt_last_0001.zkey --entropy=1234 --name="second contribution" -v
	cd circuit && snarkjs zkey export verificationkey mpt_last_0001.zkey verification_key.json

gen_mpt_last_witness:
	cd circuit && ./mpt_last_cpp/mpt_last /tmp/input_mpt_last.json mpt_last_witness.wtns
	mv circuit/output.json /tmp/output_mpt_last.json

gen_mpt_last_proof:
	cd circuit && snarkjs groth16 prove mpt_last_0001.zkey mpt_last_witness.wtns mpt_last_proof.json mpt_last_public.json
	snarkjs generatecall circuit/mpt_last_public.json circuit/mpt_last_proof.json > /tmp/mpt_last_proof.json 

gen_mpt_last_solidity: mpt_last_zkey
	cd circuit && snarkjs zkey export solidityverifier mpt_last_0001.zkey ../../src/MptLastVerifier.sol
	sed -i 's/Groth16Verifier/MptLastVerifier/' ../src/MptLastVerifier.sol

spend:
	cd circuit && circom spend.circom --r1cs --wasm --sym --c

	mv circuit/spend_cpp/main.cpp circuit/spend_cpp/main.cpp.tmp
	python3 scripts/spit_output.py < circuit/spend_cpp/main.cpp.tmp > circuit/spend_cpp/main.cpp
	rm circuit/spend_cpp/main.cpp.tmp
	cd circuit/spend_cpp && make

spend_zkey: spend
	cd circuit && snarkjs groth16 setup spend.r1cs pot12_final.ptau spend_0000.zkey
	cd circuit && snarkjs zkey contribute spend_0000.zkey spend_0001.zkey --entropy=1234 --name="second contribution" -v
	cd circuit && snarkjs zkey export verificationkey spend_0001.zkey verification_key.json

gen_spend_witness:
	cd circuit && ./spend_cpp/spend /tmp/input_spend.json spend_witness.wtns
	mv circuit/output.json /tmp/output_spend.json

gen_spend_proof:
	cd circuit && snarkjs groth16 prove spend_0001.zkey spend_witness.wtns spend_proof.json spend_public.json
	snarkjs generatecall circuit/spend_public.json circuit/spend_proof.json > /tmp/spend_proof.json 

gen_spend_solidity: spend_zkey
	cd circuit && snarkjs zkey export solidityverifier spend_0001.zkey ../../src/SpendVerifier.sol
	sed -i 's/Groth16Verifier/SpendVerifier/' ../src/SpendVerifier.sol

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} +
	rm -rf circuit/*.r1cs circuit/*.wasm circuit/*.sym circuit/*.json circuit/*.wtns circuit/mpt_first_cpp/ circuit/mpt_first_js/ circuit/mpt_path_cpp/ circuit/mpt_path_js/ circuit/mpt_last_cpp/ circuit/mpt_last_js/ circuit/spend_cpp/ circuit/spend_js/
	rm -rf ../src/MptFirstVerifier.sol ../src/MptMiddleVerifier.sol ../src/MptLastVerifier.sol ../src/SpendVerifier.sol

clean_all: clean
	rm -rf circuit/*.zkey

install: clean gen_mpt_first_solidity gen_mpt_last_solidity gen_spend_solidity
# install: clean gen_mpt_first_solidity gen_mpt_path_solidity gen_mpt_last_solidity