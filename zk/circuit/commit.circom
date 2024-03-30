pragma circom 2.1.5;

include "./utils/hasher.circom";
include "./utils/hashbytes.circom";
include "./utils/mask.circom";

template CommitLayer(maxBlocks) {
    signal input numLayerBytes;
    signal input layerBytes[maxBlocks * 136];
    signal input salt;
    signal output commit;

    component mask = Mask(maxBlocks * 136);
    mask.ind <== numLayerBytes;
    mask.in <== layerBytes;
    component hasherLower = HashBytes(maxBlocks * 136, 31);
    hasherLower.inp <== mask.out;
    component commitToLen = Hasher();
    commitToLen.left <== hasherLower.out;
    commitToLen.right <== numLayerBytes;
    component commitToLenSalt = Hasher();
    commitToLenSalt.left <== commitToLen.hash;
    commitToLenSalt.right <== salt;
    commit <== commitToLenSalt.hash;
}