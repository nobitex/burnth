pragma circom 2.1.5;

template MaskGen(n) {
    signal input ind;
    signal output out[n];

    signal eqs[n+1];
    eqs[0] <== 1;
    component eqcomps[n];
    for(var i = 0; i < n; i++) {
        eqcomps[i] = IsEqual();
        eqcomps[i].in[0] <== i;
        eqcomps[i].in[1] <== ind;
        eqs[i+1] <== eqs[i] * (1 - eqcomps[i].out);
    }

    for(var i = 0; i < n; i++) {
        out[i] <== eqs[i+1];
    }
}

template Mask(n) {
    signal input in[n];
    signal input ind;
    signal output out[n];

    component maskgen = MaskGen(n);
    maskgen.ind <== ind;

    for(var i = 0; i < n; i++) {
        out[i] <== in[i] * maskgen.out[i];
    }
}