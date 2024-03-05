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
        "0x49bC4443E05f7c05A823920CaD1c9EbaAcD7201E",
        "0xBc53027c52B0Ee6ad90347b8D03A719f30d9d7aB",
    ),
}

DEFAULT_NETWORK = "ganache"
