pragma circom 2.1.5;

include "./utils/hasher.circom";
include "./utils/hashbytes.circom";

template CommitLayer(maxBlocks) {
    signal input numLayerBytes;
    signal input layerBytes[maxBlocks * 136];
    signal input salt;
    signal output commit;

    component hasherLower = HashBytes(maxBlocks * 136, 31);
    hasherLower.inp <== layerBytes;
    component commitToLen = Hasher();
    commitToLen.left <== hasherLower.out;
    commitToLen.right <== numLayerBytes;
    component commitToLenSalt = Hasher();
    commitToLenSalt.left <== commitToLen.hash;
    commitToLenSalt.right <== salt;
    commit <== commitToLenSalt.hash;
}