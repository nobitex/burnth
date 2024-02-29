 # 🔥 Burnth

Burnth is just eth, but burnt!

Burnth is a practical implementation of [EIP-7503](https://eip7503.org). It's a relatively minimal ERC-20 smart-contract, deployed on Ethereum blockchain, allowing people to provide private proofs of burn and mint BURNTH tokens in exchange. The minting is done in a 1:1 scale, which means, for each 1 ETH you burn, you'll get 1 BURNTH.

It uses zkSNARKs under the hood to validate the Proof of Burns. The zero-knowledge protocol argues that there is an account within the state-root of a `blockRoot` (Which is a public `bytes32` value, that can be accessed in smart-contracts by: `block.blockRoot` or `blockroot(idx)`, and can be fed as a public input to zero-knowledge proof circuits).

## The circuit

The proof checks existence of some balance in a burn-address (Addresses which provably have no private-keys), by verifying a Merkle-Patricia-Trie proof.

Since Merkle-Patricia-Tries in Ethereum use keccak as their hash-function, and given that keccak is not a SNARK-friendly hash function, a circuit validating an entire MPT proof would be huge, making it practically impossible to generate proofs for using consumer-grade hardware (E.g laptops).

Instead of having a giant circuit validating a complete MPT-proof, we'll decompose our proofs into smaller arguments, and check that they are chained together outside the circuit.

Our Modified-Merkle-Patricia-Trie-Proof-Verifier consists of 3 R1CS circuits, as described below:

1. MPT-middle circuit: *There exists a layer $l_i$ with commitment $h(l_i | s)$, such that keccak($l_i$) is a substring of $l_{i-1}$*

## Usage

You'll find a Python script `burnth` in the repo, which can be used for burning ETH and minting BURNTH.

1. Burn your ETH: `burnth burn --priv-src [PRIVATE KEY OF THE SOURCE ACCOUNT] --amount [AMOUNT IN ETH]`.
   This will transfer your funds into a burn-address. The burn-address is the result of running the zk-friendly MiMC7 hash function on some preimage, that is derived for you given a random entropy saved in `burnth.priv`. (WARN: Losing this file makes you unable of minting your BURNTH!)
2. Check your burnt amounts: `burnth info`
3. Mint your BURNTH: `burnth burn --priv-fee-payer [PRIVATE KEY OF THE ACCOUNT PAYING THE FEES FOR MINT TRANSACTION] --dst-addr [ACCOUNT TO RECEIVE THE ERC-20 TOKENS] --amount [AMOUNT TO BE MINTED]`.
   It's important to use a different account for paying the minting gas fees, otherwise, the burner's identity would be revealed.
4. Congrats! Your BURNTH should now be in your wallet!