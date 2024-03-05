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
        "0x49455287eBCC42a875B40724C62519D03e2EDcff",
        "0xe5608e4945998aB5E4548Bc95b421E188095DA8E",
    ),
}

DEFAULT_NETWORK = "ganache"
