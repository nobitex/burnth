class Network:
    def __init__(self, provider_url, chain_id, contract_address):
        self.provider_url = provider_url
        self.chain_id = chain_id
        self.contract_address = contract_address


NETWORKS = {
    "sepolia": Network(
        "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
        11155111,
        "0xa1440a8B8b53a9e24fecC173d8C3821e870878A5",
    ),
    "ganache": Network(
        "http://127.0.0.1:8545", 1337, "0xa1440a8B8b53a9e24fecC173d8C3821e870878A5"
    ),
}
