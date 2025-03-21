# Create a transaction whose fee can be later update to a higher fee if it doesn't get mined on time

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
 transaction="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# Decode the provided transaction to get its txid
txid=$(bitcoin-cli -regtest decoderawtransaction "$transaction" | jq -r '.txid')

# echo "$txid"

# Define inputs using both outputs from the provided transaction.
# Set "sequence" to a value below 0xffffffff (here: 4294967293) to enable RBF.
inputs='[
  {"txid": "'$txid'", "vout": 0, "sequence": 4294967293},
  {"txid": "'$txid'", "vout": 1, "sequence": 4294967293}
]'

# echo "$inputs"

# Destination address and amount in satoshis
destination_address="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
destination_amount=20000000  # 20,000,000 satoshis

# Total input amount from the provided transaction (in satoshis)
total_input=23679108

# Calculate change amount (for now, fee is assumed zero; fee can be updated later)
change_amount=$(echo "$total_input - $destination_amount" | bc)

echo "$change_amount"

# Get a change address from your wallet "btrustwallet"
change_address=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getrawchangeaddress)

echo "$change_address"

# Create outputs JSON object: send destination_amount to destination address and return change.
outputs=$(jq -n --arg dest "$destination_address" --argjson dest_amt $destination_amount \
                --arg change "$change_address" --argjson change_amt $change_amount \
                '{($dest): $dest_amt, ($change): $change_amt}')

echo "$outputs"

# Create the raw transaction with the inputs and outputs
raw_tx=$(bitcoin-cli -regtest createrawtransaction "$inputs" "$outputs")

# Output the raw transaction hex
echo "$raw_tx"