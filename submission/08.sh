# Create a transaction whose fee can be later updated to a higher fee if it is stuck or doesn't get mined on time

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
raw_tx="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# Destination payment address and amount (in satoshis)
PAYMENT_ADDRESS="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
PAYMENT_AMOUNT=20000000  


FEE=1000

decoded=$(bitcoin-cli -regtest -rpcwallet=btrustwallet decoderawtransaction "$raw_tx")

# Extract txid and output values
txid=$(echo "$decoded" | jq -r '.txid')
vout0_value=$(echo "$decoded" | jq -r '.vout[0].value')
vout1_value=$(echo "$decoded" | jq -r '.vout[1].value')

# Convert BTC values to satoshis
vout0_sat=$(echo "scale=0; $vout0_value * 100000000 / 1" | bc)
vout1_sat=$(echo "scale=0; $vout1_value * 100000000 / 1" | bc)
total_input=$(( vout0_sat + vout1_sat ))

# echo "Decoded source txid: $txid"
# echo "UTXO 0: $vout0_sat satoshis, UTXO 1: $vout1_sat satoshis"
# echo "Total input value: $total_input satoshis"


# Change = total input - payment - fee
CHANGE_AMOUNT=$(( total_input - PAYMENT_AMOUNT - FEE ))
# echo "Change amount: $CHANGE_AMOUNT satoshis"


# Use both UTXOs with sequence < 0xffffffff-1 (e.g. 4294967293) to enable RBF.
inputs=$(jq -n --arg txid "$txid" '[
  {txid: $txid, vout: 0, sequence: 4294967293},
  {txid: $txid, vout: 1, sequence: 4294967293}
]')
# echo "Inputs JSON: $inputs"



change_address=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getrawchangeaddress)
# echo "Change address: $change_address"



outputs=$(jq -n --arg payAddr "$PAYMENT_ADDRESS" --argjson payAmt $PAYMENT_AMOUNT \
                --arg changeAddr "$change_address" --argjson chAmt $CHANGE_AMOUNT \
                '{($payAddr): $payAmt, ($changeAddr): $chAmt}')
# echo "Outputs JSON: $outputs"


raw_tx_new=$(bitcoin-cli -regtest createrawtransaction "$inputs" "$outputs")
# echo "Created RBF-enabled raw transaction:"
echo $raw_tx_new