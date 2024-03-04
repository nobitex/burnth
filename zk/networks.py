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
        "0x9561C133DD8580860B6b7E504bC5Aa500f0f06a7",
        "0xe982E462b094850F12AF94d21D470e21bE9D0E9C",
    ),
}

DEFAULT_NETWORK = "ganache"
