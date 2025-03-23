# Created a SegWit address.
ADDRESS=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" bech32)

# Add funds to the address.
bitcoin-cli -regtest -rpcwallet=btrustwallet generatetoaddress 101 "$ADDRESS" > /dev/null

# Return only the Address
echo $ADDRESS