# List the current UTXOs in your wallet.
echo 
bitcoin-cli -regtest -rpcwallet=btrustwallet listunspent | jq '.[] | {
    txid: .txid,
    vout: .vout,
    address: .address,
    amount: .amount,
    confirmations: .confirmations
}'