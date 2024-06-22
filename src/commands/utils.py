from web3 import Web3


def sign_and_send_transaction(w3, txn, priv_src):
    try:
        signed_txn = w3.eth.account.sign_transaction(txn, priv_src)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
        print(f"Transaction hash: {tx_hash.hex()}")
        print("Waiting for the transaction receipt ...")
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        if receipt.status == 1:
            print("Transaction status: Success")
        else:
            print("Transaction status: Failure")
            tx = w3.eth.get_transaction(tx_hash)
            receipt = w3.eth.get_transaction_receipt(tx_hash)
            revert_reason = w3.eth.call(
                {"to": tx["to"], "data": tx["input"], "from": tx["from"]},
                block_identifier=receipt["blockNumber"],
            )
            print(f"Revert reason: {revert_reason}")
    except Exception as e:
        print(f"An error occurred: {e}")
