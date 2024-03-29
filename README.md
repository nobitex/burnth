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

```
sudo apt install npm
sudo npm install -g snarkjs
```

Here you can find the installation guide of circom: https://docs.circom.io/getting-started/installation/

1. Clone the `burnth` repository, `cd` into it, and then perform a `make` to download the trusted-setup params:

    ```
    git clone https://github.com/nobitex/burnth && cd burnth
    make
    ```
2. You'll also need to have the some python package installed on your system:

    `sudo pip3 install -r requirements.txt`

3. Burn your ETH:

    `./burnth burn --priv-src [PRIVATE KEY OF THE SOURCE ACCOUNT] --amount [AMOUNT IN ETH]`

    This will transfer your funds into a burn-address. The burn-address is the result of running the zk-friendly MiMC7 hash function on some preimage, that is derived for you given a random entropy saved in `burnth.priv`. (WARN: Losing this file makes you unable of minting your BURNTH!)

4. Check your burnt amounts:

    `./burnth info`

5. Mint your BURNTH:

    `./burnth mint --priv-fee-payer [PRIVATE KEY OF THE ACCOUNT PAYING THE FEES FOR MINT TRANSACTION] --dst-addr [ACCOUNT TO RECEIVE THE ERC-20 TOKENS] --src-burn-addr [THE BURN-ADDRESS YOU WANT TO CONSUME]`

    It's important to use a different account for paying the minting gas fees, otherwise, the burner's identity would be revealed.
6. Congrats! Your BURNTH should now be in your wallet! Find it in your MetaMask wallet: the token contract address of BURNTH on Sepolia testnet is: `0x98F5594BdE9d5D3c214457A232F527f8Ae0bafE4`

## The circuit

The proof checks existence of some balance in a burn-address (Addresses which provably have no private-keys), by verifying a Merkle-Patricia-Trie proof.

Since Merkle-Patricia-Tries in Ethereum use keccak as their hash-function, and given that keccak is not a SNARK-friendly hash function, a circuit validating an entire MPT proof would be huge, making it practically impossible to generate proofs for using consumer-grade hardware (E.g laptops).

Instead of having a giant circuit validating a complete MPT-proof, we'll decompose our proofs into smaller arguments, and check that they are chained together outside the circuit.

Our Modified-Merkle-Patricia-Trie-Proof-Verifier consists of 3 R1CS circuits, as described below:

1. MPT-middle circuit: There exists a layer $`l_i`$ with commitment $`h(l_i | s)`$, such that $`keccak(l_i)`$ is a substring of $`l_{i-1}`$, with commitment $`h(l_{i-1} | s)`$ (Where $h$ is a SNARK-friendly hash function and $s$ is a random salt, added while commiting to the layer, so that verifier cannot guess the layer)
2. MPT-last circuit: There exists an an account within a layer $l_{last}$, with commitment $`h(l_i | s)`$ that it's public-key is MiMC7 of some preimage $p$ ($`MiMC7(p,p)`$). Nullifier is $`MiMC7(p,0)`$

There is also an extra Spend circuit, allowing you to partially mint your burnt amounts, ***without exposing the remaining amounts!***

***The parameter files are approximately 500MB and it takes around 1 minute to generate a single proof of burn.***

## License

The project is licensed under GPL v3.

The keccak circuits are implemented by https://github.com/vocdoni and licensed under GPL v3. Check: https://github.com/vocdoni/keccak256-circom/blob/master/LICENSE
