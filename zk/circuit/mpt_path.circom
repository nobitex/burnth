pragma circom 2.1.5;

include "./utils/keccak/keccak.circom";
include "./utils/substring_finder.circom";
include "./utils/hasher.circom";
include "./utils/padding.circom";
include "./utils/hashbytes.circom";

template CommitLayer(maxBlocks) {
    signal input layerBytes;
    signal input numLayerBytes[maxBlocks * 136];

    component hasherLower = HashBytes(maxBlocks * 136, 31);
    hasherLower.inp <== layerBytes[0];
    component commitLowerToLen = Hasher();
    commitLowerToLen.left <== hasherLower.out;
    commitLowerToLen.right <== numLayerBytes[0];
    component commitLowerToSalt = Hasher();
    commitLowerToSalt.left <== commitLowerToLen.hash;
    commitLowerToSalt.right <== salt;
    commitLower <== commitLowerToSalt.hash;
}

template KeccakLayerChecker(maxBlocks, maxLayers) {
    signal input isTop;
    isTop * (1 - isTop) === 0;

    signal input numLayerBytes[maxLayers];
    signal input layerBytes[maxLayers][maxBlocks * 136];
    signal numLayers;

    component padders[maxLayers];
    component layer_bitters[maxLayers];
    component keccakers[maxLayers];
    component substring_checkers[maxLayers - 1];

    for(var i = 0; i < maxLayers; i++) {
        padders[i] = Padding(maxBlocks, 136);
        padders[i].a <== layerBytes[i];
        padders[i].aLen <== numLayerBytes[i];
        layer_bitters[i] = BytesToBits(maxBlocks * 136);
        layer_bitters[i].bytes <== padders[i].out;
    }
    // Check if keccak(layer[i]) is in layer[i+1]
    for(var i = 0; i < maxLayers - 1; i++) {
        keccakers[i] = Keccak(maxBlocks);
        keccakers[i].in <== layer_bitters[i].bits;
        keccakers[i].blocks <== padders[i].num_blocks;
        substring_checkers[i] = substringCheck(maxBlocks, 136 * 8, 32 * 8);
        substring_checkers[i].subInput <== keccakers[i].out;
        substring_checkers[i].numBlocks <== padders[i+1].num_blocks;
        substring_checkers[i].mainInput <== layer_bitters[i+1].bits;
        substring_checkers[i].out === 1 - isTop;
    }

    signal input salt;
    signal output commitUpper;
    signal output commitLower;

    // Commit to lowerLayer
    component hasherLower = HashBytes(maxBlocks * 136, 31);
    hasherLower.inp <== layerBytes[0];
    component commitLowerToLen = Hasher();
    commitLowerToLen.left <== hasherLower.out;
    commitLowerToLen.right <== numLayerBytes[0];
    component commitLowerToSalt = Hasher();
    commitLowerToSalt.left <== commitLowerToLen.hash;
    commitLowerToSalt.right <== salt;
    commitLower <== commitLowerToSalt.hash;

    signal lowerLayerHash;
    component bits2num = Bits2NumBigendian(32 * 8);
    bits2num.in <== keccakers[0].out;
    lowerLayerHash <== bits2num.out;

    // Commit to upperLayer
    component hasherUpper = HashBytes(maxBlocks * 136, 31);
    hasherUpper.inp <== layerBytes[1];
    component commitUpperToLen = Hasher();
    commitUpperToLen.left <== hasherUpper.out;
    commitUpperToLen.right <== numLayerBytes[1];
    component commitUpperToSalt = Hasher();
    commitUpperToSalt.left <== commitUpperToLen.hash;
    commitUpperToSalt.right <== salt;
    commitUpper <==  commitUpperToSalt.hash + isTop * (lowerLayerHash - commitUpperToSalt.hash);
}

component main = KeccakLayerChecker(4, 2);