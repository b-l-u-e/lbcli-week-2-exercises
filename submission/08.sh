# Create a transaction whose fee can be later updated to a higher fee if it is stuck or doesn't get mined on time

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
raw_tx="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# P2SH destination
RECIPIENT="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
AMOUNT_TO_SEND=0.2
FEE=0.0001


# Decode raw TX
tx_json=$(bitcoin-cli -regtest -rpcwallet=btrustwallet decoderawtransaction "$raw_tx")


if [[ -z "$tx_json" ]]; then
  echo "❌ Failed to decode raw transaction. Check if RAW_TX is valid."
  exit 1
fi

TXID=$(echo "$tx_json" | jq -r '.txid')

INPUTS=$(echo "$tx_json" | jq -c --arg txid "$TXID" '
  [ .vout[] | {txid: $txid, vout: .n, sequence: 1} ]
')

TOTAL_INPUT=$(echo "$tx_json" | jq '[.vout[].value] | add')

# Validate extracted values
if [[ -z "$TXID" || -z "$TOTAL_INPUT" || "$TOTAL_INPUT" == "null" ]]; then
  echo "❌ Failed to extract TXID or input value."
  exit 1
fi

CHANGE=$(echo "$TOTAL_INPUT - $AMOUNT_TO_SEND - $FEE" | bc -l 2>/dev/null)
CHANGE=$(printf "%.8f" "$CHANGE")


if [[ -z "$CHANGE" || $(echo "$CHANGE < 0" | bc -l) -eq 1 ]]; then
  echo "❌ ERROR: Not enough funds. Only $TOTAL_INPUT BTC available."
  exit 1
fi


CHANGE_ADDRESS=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getrawchangeaddress)
if [[ -z "$CHANGE_ADDRESS" ]]; then
  echo "❌ Failed to get change address."
  exit 1
fi

# Create outputs JSON
# OUTPUTS=$(jq -n \
#   --arg to "$RECIPIENT" \
#   --arg amt "$AMOUNT_TO_SEND" \
#   --arg change "$CHANGE" \
#   --arg changeAddr "$CHANGE_ADDRESS" \
#   '{
#     ($to): ($amt | tonumber),
#     ($changeAddr): ($change | tonumber)
#   }')

OUTPUTS=$(jq -n \
  --arg to "$RECIPIENT" \
  --arg amt "$AMOUNT_TO_SEND" \
  '{ ($to): ($amt | tonumber) }')



# Create raw transaction
rawtx=$(bitcoin-cli -regtest -rpcwallet=btrustwallet createrawtransaction "$INPUTS" "$OUTPUTS" 2>/dev/null)


echo $rawtx


