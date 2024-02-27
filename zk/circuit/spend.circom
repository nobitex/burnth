pragma circom 2.1.5;

include "./utils/hasher.circom";

template Spend() {
    signal input balance;
    signal input salt;
    signal output coin;

    component coinHasher = Hasher();
    coinHasher.left <== balance;
    coinHasher.right <== salt;
    coin <== coinHasher.hash;

    signal input withdrawnBalance;
    signal output remainingCoin;

    component remainingCoinHasher = Hasher();
    remainingCoinHasher.left <== balance - withdrawnBalance;
    remainingCoinHasher.right <== salt;
    remainingCoin <== remainingCoinHasher.hash;
}

component main {public [withdrawnBalance]} = Spend();