# Create a raw transaction with an amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
 transaction="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# Get the txid of the provided transaction
txid=$(bitcoin-cli -regtest decoderawtransaction "$transaction" | jq -r '.txid')

# echo "$txid"

# Define inputs using both outputs (vout indices 0 and 1) from the provided transaction.
# According to previous calculations:
#   vout 0 = 16,430,198 satoshis
#   vout 1 = 7,248,910 satoshis
# Total = 23,679,108 satoshis.
inputs='[
  {"txid": "'$txid'", "vout": 0},
  {"txid": "'$txid'", "vout": 1}
]'

# echo "$inputs"

# Destination address and amount (in satoshis)
destination_address="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
destination_amount=20000000  # 20,000,000 satoshis

# Total input amount (from the provided transaction)
total_input=23679108

# Calculate the change amount (assuming zero fee for simplicity)
change_amount=$(echo "$total_input - $destination_amount" | bc)
# echo "$change_amount"

# Get a change address from your wallet "btrustwallet"
change_address=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getrawchangeaddress)

# echo "$change_address"

# Create the outputs JSON object. It sends 20,000,000 satoshis to the destination,
# and returns the remaining change to your wallet.
outputs=$(jq -n --arg dest "$destination_address" --argjson dest_amt $destination_amount \
                --arg change "$change_address" --argjson change_amt $change_amount \
                '{($dest): $dest_amt, ($change): $change_amt}')

# echo "$outputs"

# Create the raw transaction using the inputs and outputs
raw_tx=$(bitcoin-cli -regtest createrawtransaction "$inputs" "$outputs")

# Output the raw transaction hex
echo "$raw_tx"



