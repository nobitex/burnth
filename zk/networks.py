class Network:
    def __init__(
        self, provider_url, chain_id, burnth_contract_addr, wormcash_contract_addr
    ):
        self.provider_url = provider_url
        self.chain_id = chain_id
        self.burnth_contract_addr = burnth_contract_addr
        self.wormcash_contract_addr = wormcash_contract_addr


NETWORKS = {
    "sepolia": Network(
        "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
        11155111,
        "",
        "",
    ),
    "ganache": Network(
        "http://127.0.0.1:8545",
        1337,
        "0x457f0f599CC62A41B221cC94bC9d5Cf0012D21A8",
        "0x0937F524C8A7d3D6Af3023875CF6c7f293F3B994",
    ),
}

DEFAULT_NETWORK = "ganache"
