# Using Your Ethereum Node

Once your node is fully synced, you have a private, censorship-resistant
window into Ethereum.

## Accessing Your Node

Ethereum on ARM includes a pre-configured nginx proxy that exposes your
node's execution RPC on port 80. This means any wallet or dApp on your
local network can connect to your node without any extra configuration —
just point it to your board's local IP address.

How it works:
- The execution client binds its JSON-RPC to localhost:8545 only
- nginx listens on port 80 and proxies requests to localhost:8545
- Devices on your LAN reach the node via http://<board-ip>

You can find your board's local IP with:

    hostname -I

The CL Beacon API (port 5052) remains on localhost only and is not
proxied — it is only needed for validator tooling and internal scripts.

---

## Endpoints

From the board itself:
- EL JSON-RPC  : http://localhost:8545
- CL Beacon API: http://localhost:5052

From another device on your LAN (wallet, dApp, MetaMask):
- EL JSON-RPC  : http://<board-ip>

---

## Check a Wallet Balance

Replace `<ADDRESS>` with any Ethereum address. Result is in Wei —
divide by 10^18 to get ETH.

    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["<ADDRESS>","latest"],"id":1}' | python3 -c "import sys,json; wei=int(json.load(sys.stdin)['result'],16); print(f'{wei/1e18:.6f} ETH')"

---

## Get the Latest Block Number

    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | python3 -c "import sys,json; print(int(json.load(sys.stdin)['result'],16))"

---

## Get Block Details

Replace `<BLOCK_NUMBER>` with a decimal block number.

    BLOCK_HEX=$(python3 -c "print(hex(<BLOCK_NUMBER>))")
    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d "{\\"jsonrpc\\":\\"2.0\\",\\"method\\":\\"eth_getBlockByNumber\\",\\"params\\":[\\"$BLOCK_HEX\\",false],\\"id\\":1}" | python3 -m json.tool

---

## Get Transaction Details

Replace `<TX_HASH>` with a transaction hash.

    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["<TX_HASH>"],"id":1}' | python3 -m json.tool

---

## Get the Current Gas Price

    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' | python3 -c "import sys,json; wei=int(json.load(sys.stdin)['result'],16); print(f'{wei/1e9:.2f} Gwei')"

---

## Get Pending Transaction Count for an Address

Useful for checking the nonce before sending a transaction.

    curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["<ADDRESS>","pending"],"id":1}' | python3 -c "import sys,json; print('Nonce:', int(json.load(sys.stdin)['result'],16))"

---

## Check Beacon Chain Head

    curl -s http://localhost:5052/eth/v1/beacon/headers/head | python3 -m json.tool

---

## Check Validator Status (if staking)

Replace `<VALIDATOR_INDEX>` with your validator index number.

    curl -s http://localhost:5052/eth/v1/beacon/states/head/validators/<VALIDATOR_INDEX> | python3 -m json.tool

---

## Use Your Node as a Custom RPC in MetaMask or a Wallet

Thanks to the nginx proxy you can connect any wallet on your local
network directly to your node with no extra setup.

In MetaMask or any wallet, add a custom network with these settings:

From the board itself:
- RPC URL  : http://localhost:8545
- Chain ID : 1
- Symbol   : ETH

From another device on your LAN:
- RPC URL  : http://<board-ip>
- Chain ID : 1
- Symbol   : ETH

For testnets, connect from the board directly:
- Hoodi   RPC: http://localhost:8545  Chain ID: 560048
- Sepolia RPC: http://localhost:8545  Chain ID: 11155111
