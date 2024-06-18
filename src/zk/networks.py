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
        "0x98F5594BdE9d5D3c214457A232F527f8Ae0bafE4",
        "0x905F36D7ab973C4eDf77cE4456b4f9b0099632cF",
    ),
    "ganache": Network(
        "http://127.0.0.1:8545",
        1337,
        "0x3De99aB4190E49f5c6054c7A0347b0267f724f55",
        "0x44e666bB362EeD593F59815aA1D3164566d05000",
    ),
}

DEFAULT_NETWORK = "ganache"
