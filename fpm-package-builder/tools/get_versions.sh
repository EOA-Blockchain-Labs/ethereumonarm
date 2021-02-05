#!/usr/bin/env bash

echo -n "besu="; curl -s "https://api.github.com/repos/hyperledger/besu/releases/latest" | jq '.name' | tr -d '"' | tr -d 'v'
echo -n "deposit="; curl -s "https://api.github.com/repos/ethereum/eth2.0-deposit-cli/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v"
echo -n "geth="; curl -s "https://api.github.com/repos/ethereum/go-ethereum/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v"
echo -n "ipfs="; curl -s "https://api.github.com/repos/ipfs/go-ipfs/releases/latest" | jq .tag_name | tr -d  '"'| tr -d "v"
echo -n "lighthouse="; curl -s "https://api.github.com/repos/sigp/lighthouse/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v"
echo -n "nethermind="; curl -s "https://api.github.com/repos/NethermindEth/nethermind/releases/latest" | jq '.name' | tr -d  '"'| tr -d "v"
echo -n "nimbus="; curl -s "https://api.github.com/repos/status-im/nimbus-eth2/releases/latest" | jq '.name' | tr -d '"' | tr -d 'v'
echo -n "openethereum="; curl -s "https://api.github.com/repos/openethereum/openethereum/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v"
echo -n "prysm="; curl -s "https://api.github.com/repos/prysmaticlabs/prysm/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v"
echo -n "teku="; curl -s "https://api.github.com/repos/ConsenSys/teku/releases/latest" | jq '.name' | tr -d '"' | tr -d 'v'
