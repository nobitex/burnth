.PHONY = all

circuit/mpt_path.r1cs: circuit/mpt_path.circom circuit/utils/*.circom
	cd circuit && circom mpt_path.circom --r1cs --wasm --sym --c
circuit/mpt_last.r1cs: circuit/mpt_last.circom circuit/utils/*.circom
	cd circuit && circom mpt_last.circom --r1cs --wasm --sym --c
circuit/spend.r1cs: circuit/spend.circom circuit/utils/*.circom
	cd circuit && circom spend.circom --r1cs --wasm --sym --c

circuit/mpt_path_cpp/mpt_path: circuit/mpt_path.r1cs
	mv circuit/mpt_path_cpp/main.cpp circuit/mpt_path_cpp/main.cpp.tmp && python3 scripts/spit_output.py < circuit/mpt_path_cpp/main.cpp.tmp > circuit/mpt_path_cpp/main.cpp && rm circuit/mpt_path_cpp/main.cpp.tmp
	cd circuit/mpt_path_cpp && make
circuit/mpt_last_cpp/mpt_last: circuit/mpt_last.r1cs
	mv circuit/mpt_last_cpp/main.cpp circuit/mpt_last_cpp/main.cpp.tmp && python3 scripts/spit_output.py < circuit/mpt_last_cpp/main.cpp.tmp > circuit/mpt_last_cpp/main.cpp && rm circuit/mpt_last_cpp/main.cpp.tmp
	cd circuit/mpt_last_cpp && make
circuit/spend_cpp/spend: circuit/spend.r1cs
	mv circuit/spend_cpp/main.cpp circuit/spend_cpp/main.cpp.tmp && python3 scripts/spit_output.py < circuit/spend_cpp/main.cpp.tmp > circuit/spend_cpp/main.cpp && rm circuit/spend_cpp/main.cpp.tmp
	cd circuit/spend_cpp && make