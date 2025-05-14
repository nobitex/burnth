<p align="center">
  <img width=160 src="https://github.com/nobitex/burnth/assets/4275654/e4a87112-2d10-4e4e-b93b-a9d23fd0f94c" />
</p>
 
 # 🔥 Burnth / 🪱 WormCash

Burnth is just eth, but burnt!

Burnth is a practical implementation of [EIP-7503](https://eip7503.org). It's a relatively minimal ERC-20 smart-contract, deployed on Ethereum blockchain, allowing people to provide private proofs of burn and mint BURNTH tokens in exchange. The minting is done in a 1:1 scale, which means, for each 1 ETH you burn, you'll get 1 BURNTH.

It uses zkSNARKs under the hood to validate the proof-of-burns. The zero-knowledge protocol argues that there is an account within the state-root of a `blockRoot` (Which is a public `bytes32` value, that can be accessed in smart-contracts by: `block.blockRoot` or `blockroot(idx)`, and can be fed as a public input to zero-knowledge proof circuits), with an unspendable address (I.e burn-address). The circuit checks the unspendability by checking if the address is in fact equal with the output of a hash-function (In case we use MiMC7, which is a ZK friendly hash function).

WormCash on the other hand, is a separate crypto-token which can be minted by spending Burnth, but unlike Burnth, its emission is limited. This is done in order to make it economically viable to use it as an independent and valuable cryptoasset. A limited number of WormCashs can be generated per ethereum block, and the generated tokens are distributed based on amount of Burnth tokens consumed per user on that block.

People can burn ETH, convert it into WormCash, and swap it back with ETH on a decentralized exchange. This makes the philosophy behind EIP-7503 viable, without needing any change to the core Ethereum protocol!

## Usage

Burnth is up on Sepolia testnet. You can burn some of your Sepolia ETH and give it a try!

The project uses Circom/SnarkJS as its ZK proving system, thus you'll need to have both `snarkjs` and `circom` installed on your system in order to generate proofs:

```bash
sudo apt install npm
sudo npm install -g snarkjs
```

Here you can find the installation guide of circom: https://docs.circom.io/getting-started/installation/

- Clone the `burnth` repository, `cd` into it, and then perform a `make` to download the trusted-setup params:

    ```bash
    git clone https://github.com/nobitex/burnth && cd burnth
    make
    ```
- You'll also need to have the some python package installed on your system:

    `sudo pip3 install -r requirements.txt`

### Burnth 

To use burnth project you have 4 commands you can use: burn, mint, spend, info.
and you can run the project on ganache or use our deployed sepolia contract.
to run the project locally on your device run:
```bash
ganache
# add one of the accounts private keys to Makefile
```
to deploy the burnth and wormcash smart contracts locally, run:
```bash
make deploy
# the deployed addresses will automatically be added to networks file
```

### commands

#### 1. Info:
the info command is used to show you the detail of burnth wallet from including burnt addresses that will be used to mint the burnt ETH, the minted amount index that will be used to partially mint burnt eth, and to get the BURNTH balance.


```bash
python3 src/burnth info --network NETWORK
```

#### 2. Burn:
the burn command is used to burn a specific amount of ETH from the provided private key and creates a burn address that proves the burnt amount.

```bash
python3 src/burnth burn --priv-src PRIVATE_KEY --amount AMOUNT --network NETWORK 
```
run the info command to get the burn address, for example :
```
Your burn-addresses:
#1: 0x05c173E9Db4D04dd3C907A8C4D0f400437F7a86C (10 ETH)
```

#### 3. Mint:
the mint command is used to mint the ETH amount related to a burnt address.
to mint the total burnt amount run the mint command without --encrypted, but to mint the burnt amount partially add the --encrypted tag.

```bash
# total mint
# the total burnt amount will be minted to the RECEIVER_ADDRESS after this command
python3 src/burnth mint --priv-fee-payer PRIVATE_KEY --dst-addr RECEIVER_ADDRESS --src-burn-addr BURN_ADDRESS --network NETWORK

# partial mint
# to mint the burnt amount to the RECEIVER_ADDRESS you need to use the spend command
python3 src/burnth mint --priv-fee-payer PRIVATE_KEY --dst-addr RECEIVER_ADDRESS --src-burn-addr BURN_ADDRESS --network NETWORK --encrypted
```
* the burn address list is accessible through info command, run the info command and if you used the encrypted tag the minted BURNTH is now added to your coins, for example:

```
Your burn-addresses:
#1: 0x05c173E9Db4D04dd3C907A8C4D0f400437F7a86C (10 ETH)
Your coins:
[IDX: 1] Amount: 10 ETH | Salt: 9364906274990760141348533961953457098325637997490634627852333616901136153523

```


#### 4. spend:
the spend command is used to mint a specific amount of burnt ETH to the provided RECEIVER_ADDRESS.

```bash
python3 src/burnth spend --priv-sender PRIVATE_KEY --dst-addr RECEIVER_ADDRESS --coin-index INDEX --amount PARTIAL_AMOUNT --network NETW0RK 

```
- the relative coin index is accessible through info command .

### WormCash 

To use wormcash project you have 3 commands you can use: participate, claim, info.
keep in mind that you should already have BURNTH token in your account to able to interact with wormcash project.

#### 1. Info:
the info command is used to show your WRM balance.

```bash
python3 src/wormcash info --priv-src PRIVATE_KEY --network NETWORK
```

#### 2  . participate:
the participate command is used to include you in the wormcash project, by running this command you will approve to send AMOUNT*NUMBER_EPOCH from your burnth tokens to the wormcash contract, after the epoch amounts is passed you can claim your reward.

```bash
python3 src/wormcash participate  --priv-src PRIVATE_KEY --amount-per-epoch AMOUNT --num-epochs NUMBER_EPOCH --network NETWORK

```

#### 2  . claim:
the claim command is used to mint the reward WRM token to provided account.

```bash
python3 src/wormcash claim --priv-src PRIVATE_KEY --starting-epoch STARTING_EPOCH --num-epochs NUM_EPOCH --network NETWORK

```
- Now use the info command to check your wormcash balance.

## The circuit

The proof checks existence of some balance in a burn-address (Addresses which provably have no private-keys), by verifying a Merkle-Patricia-Trie proof.

Since Merkle-Patricia-Tries in Ethereum use keccak as their hash-function, and given that keccak is not a SNARK-friendly hash function, a circuit validating an entire MPT proof would be huge, making it practically impossible to generate proofs for using consumer-grade hardware (E.g laptops).

Instead of having a giant circuit validating a complete MPT-proof, we'll decompose our proofs into smaller arguments, and check that they are chained together outside the circuit.

Our Modified-Merkle-Patricia-Trie-Proof-Verifier consists of 3 R1CS circuits, as described below:

1. MPT-middle circuit: There exists a layer $`l_i`$ with commitment $`h(l_i | s)`$, such that $`keccak(l_i)`$ is a substring of $`l_{i-1}`$, with commitment $`h(l_{i-1} | s)`$ (Where $h$ is a SNARK-friendly hash function and $s$ is a random salt, added while commiting to the layer, so that verifier cannot guess the layer)
2. MPT-last circuit: There exists an an account within a layer $l_{last}$, with commitment $`h(l_i | s)`$ that it's public-key is MiMC7 of some preimage $p$ ($`MiMC7(p,p)`$). Nullifier is $`MiMC7(p,0)`$

There is also an extra Spend circuit, allowing you to partially mint your burnt amounts, ***without exposing the remaining amounts!***
to spend your coin you need to mint your coins with an extra --enctypted argument, then proceed to spend your encrypted coins.

***The parameter files are approximately 500MB and it takes around 1 minute to generate a single proof of burn.***

## License

The project is licensed under both GPL v3 and MIT.

The keccak circuits are implemented by https://github.com/vocdoni and licensed under GPL v3. Check: https://github.com/vocdoni/keccak256-circom/blob/master/LICENSE
