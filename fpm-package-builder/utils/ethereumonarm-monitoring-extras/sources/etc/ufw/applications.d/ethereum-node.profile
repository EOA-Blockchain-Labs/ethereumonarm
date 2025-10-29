# ====================================================================
# UFW Application Profiles for Ethereum Node Stack (2025)
# Ship via: /etc/ufw/applications.d/ethereum-node.profile
# All profiles are inert until the admin runs:
#     ufw allow "<Profile Name>"
# ====================================================================

[Ethereum EL P2P]
title=Ethereum EL P2P
description=Execution Layer P2P for Geth/Nethermind/Besu/Erigon/Reth (listen+discv5)
ports=30303/tcp|30303/udp

[Ethereum EL P2P Alt]
title=Ethereum EL P2P Alt
description=Alternate Execution Layer P2P (e.g. Reth/Erigon variants)
ports=30304/tcp|30304/udp

[Ethereum CL P2P]
title=Ethereum CL P2P
description=Consensus Layer P2P for Lighthouse/Teku/Nimbus/Lodestar/Grandine
ports=9000/tcp|9000/udp

[Lighthouse QUIC]
title=Lighthouse QUIC
description=Optional QUIC transport (UDP/9001) for Lighthouse libp2p
ports=9001/udp

[Prysm P2P]
title=Prysm P2P
description=Prysm libp2p (TCP 13000) and discovery (UDP 12000)
ports=13000/tcp|12000/udp

[Prysm QUIC]
title=Prysm QUIC
description=Optional QUIC (UDP/13000) for Prysm ≥v5.x
ports=13000/udp

[OP Stack P2P]
title=OP Stack P2P
description=Execution-layer P2P for op-geth (follows geth defaults)
ports=30303/tcp|30303/udp

[OP Node P2P]
title=OP Node P2P
description=op-node QUIC/P2P (enable only if running op-node)
ports=9222/tcp|9222/udp

[Erigon Snap]
title=Erigon Snap
description=Erigon BitTorrent-based Snap sync (optional; open only during sync)
ports=42069/tcp|42069/udp

[Consensus Beacon REST]
title=Consensus Beacon REST
description=Beacon node REST API (5052/TCP); restrict to localhost or trusted subnets
ports=5052/tcp

[Execution RPC HTTP]
title=Execution RPC HTTP
description=Execution JSON-RPC HTTP (8545/TCP); restrict to localhost or trusted subnets
ports=8545/tcp

[Execution RPC WS]
title=Execution RPC WS
description=Execution JSON-RPC WebSocket (8546/TCP); restrict to localhost or trusted subnets
ports=8546/tcp

[Engine API]
title=Engine API
description=Engine API (EL<->CL, 8551/TCP); restrict to localhost or EL/CL pair only
ports=8551/tcp

[Besu Metrics]
title=Besu Metrics
description=Besu Prometheus metrics endpoint (9545/TCP); expose only to trusted hosts
ports=9545/tcp

[Erigon Metrics]
title=Erigon Metrics
description=Erigon metrics endpoint (6061/TCP); expose only to trusted hosts
ports=6061/tcp

[Erigon pprof]
title=Erigon pprof
description=Erigon profiling endpoint (6060/TCP); expose only to trusted hosts
ports=6060/tcp

[Reth Metrics]
title=Reth Metrics
description=Reth Prometheus metrics endpoint (9001/TCP); expose only to trusted hosts
ports=9001/tcp