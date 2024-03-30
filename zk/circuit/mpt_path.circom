pragma circom 2.1.5;

include "./utils/keccak/keccak.circom";
include "./utils/substring_finder.circom";
include "./utils/hasher.circom";
include "./utils/padding.circom";
include "./utils/hashbytes.circom";
include "./utils/utils.circom";
include "./utils/mask.circom";
include "./commit.circom";

template KeccakLayerChecker(maxBlocks, maxLayers) {
    signal input isTop;
    isTop * (1 - isTop) === 0;

    signal input numLayerBytes[maxLayers];
    signal input layerBytes[maxLayers][maxBlocks * 136];
    signal input numLayers;

    component maskgen = MaskGen(maxLayers);
    maskgen.ind <== numLayers;

    component padders[maxLayers];
    component layer_bitters[maxLayers];
    for(var i = 0; i < maxLayers; i++) {
        padders[i] = Padding(maxBlocks, 136);
        padders[i].a <== layerBytes[i];
        padders[i].aLen <== numLayerBytes[i];
        layer_bitters[i] = BytesToBits(maxBlocks * 136);
        layer_bitters[i].bytes <== padders[i].out;
    }

    // Check if keccak(layer[i]) is in layer[i+1]
    component keccakers[maxLayers];
    component substring_checkers[maxLayers - 1];
    for(var i = 0; i < maxLayers - 1; i++) {
        keccakers[i] = Keccak(maxBlocks);
        keccakers[i].in <== layer_bitters[i].bits;
        keccakers[i].blocks <== padders[i].num_blocks;
        substring_checkers[i] = substringCheck(maxBlocks, 136 * 8, 32 * 8);
        substring_checkers[i].subInput <== keccakers[i].out;
        substring_checkers[i].numBlocks <== padders[i+1].num_blocks;
        substring_checkers[i].mainInput <== layer_bitters[i+1].bits;

        substring_checkers[i].out * maskgen.out[i] === maskgen.out[i];
    }

    signal input salt;
    signal output commitUpper;
    signal output commitLower;

    component commiterLower = CommitLayer(maxBlocks);
    commiterLower.numLayerBytes <== numLayerBytes[0];
    commiterLower.layerBytes <== layerBytes[0];
    commiterLower.salt <== salt;
    commitLower <== commiterLower.commit;

    signal selectedLayerBytes[maxBlocks * 136];
    signal numSelectedLayerBytes;
    component selectors[maxBlocks * 136];
    for(var i = 0; i < maxBlocks * 136; i++) {
        selectors[i] = Selector(maxLayers);
        for(var j = 0; j < maxLayers; j++) {
            selectors[i].vals[j] <== layerBytes[j][i];
        }
        selectors[i].select <== numLayers;
        selectedLayerBytes[i] <== selectors[i].out;
    }
    component numBytesSelectors = Selector(maxLayers);
    numBytesSelectors.vals <== numLayerBytes;
    numBytesSelectors.select <== numLayers;
    numSelectedLayerBytes <== numBytesSelectors.out;

    component keccakSelectors[32 * 8];
    signal selectedLayerKeccak[32 * 8];
    for(var i = 0; i < 32 * 8; i++) {
        keccakSelectors[i] = Selector(maxLayers - 1);
        for(var j = 0; j < maxLayers - 1; j++) {
            keccakSelectors[i].vals[j] <== keccakers[j].out[i];
        }
        keccakSelectors[i].select <== numLayers;
        selectedLayerKeccak[i] <== keccakSelectors[i].out;
    }

    signal lowerLayerHash;
    component bits2num = Bits2NumBigendian(32 * 8);
    bits2num.in <== selectedLayerKeccak;
    lowerLayerHash <== bits2num.out;

    component commiterUpper = CommitLayer(maxBlocks);
    commiterUpper.numLayerBytes <== numSelectedLayerBytes;
    commiterUpper.layerBytes <== selectedLayerBytes;
    commiterUpper.salt <== salt;
    commitUpper <== commiterUpper.commit + isTop * (lowerLayerHash - commiterUpper.commit);
}

component main = KeccakLayerChecker(1, 3);