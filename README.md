# Fabric Network Orchestrator (FNO) - Experimental Evaluation

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![HLF Version](https://img.shields.io/badge/Hyperledger_Fabric-v2.5-orange.svg)](https://www.hyperledger.org/)
[![Target](https://img.shields.io/badge/Research-SBLP_2026-green.svg)](https://sblp.org.br/)

This repository contains the experimental evaluation and benchmark scenarios for the **Fabric Network Orchestrator (FNO)**, a domain-specific model-driven CLI tool designed to simplify the deployment, configuration, and validation of Hyperledger Fabric networks. 

By defining the desired network architecture in a single, high-level YAML specification, FNO handles cryptographic identity generation, docker-compose configuration orchestration, channel creation, and chaincode deployment, while performing rigorous syntactic and semantic checks.

---

## 📊 Benchmark Results: Lines of Code (LoC)

To evaluate the efficiency of FNO, we compare the required Lines of Code (LoC) to deploy identical networks under three environments:
1. **Baseline**: Manual deployment using raw Docker Compose files, `configtx.yaml` profiles, and custom shell scripting.
2. **Fablo**: A popular open-source generator tool for Hyperledger Fabric networks.
3. **FNO (Ours)**: Our proposed model-driven orchestration approach.

The following table summarizes the comparative LoC for five standard deployment scenarios:

| Scenario | Network Characteristics | Baseline (LoC) | Fablo (LoC) | FNO (LoC) |
| :--- | :--- | :---: | :---: | :---: |
| **Scenario s1** | 2 Orgs, 1 Channel, 1 Peer/Org, 1 Orderer (Org1) | 594 | 31 | **29** |
| **Scenario s2** | 5 Orgs, 1 Channel, 2 Peers/Org, 1 Orderer (Org1) | 1,518 | **52** | 57 |
| **Scenario s3** | 3 Orgs, 3 Channels, 1 Peer/Org, 1 Orderer (Org1) | 851 | 52 | **44** |
| **Scenario s4** | 3 Orgs, 1 Channel, Exposed Ports, 2 Chaincodes, Endorsement Policy | 594 | *N/A (Unsupported)* | **36** |
| **Scenario s5** | 3 Orgs, 1 Channel, Exposed Ports, Private Data Collections, 3 Chaincodes | 822 | 60 | **58** |

### Key Takeaways
> [!TIP]
> **FNO vs. Baseline**: FNO achieves an average of **~95% reduction** in Lines of Code compared to manual baseline configurations, significantly accelerating setup time and minimizing manual configuration mistakes.
>
> **FNO vs. Fablo**: FNO matches the conciseness of Fablo in simpler topologies and surpasses it in versatility. Crucially, FNO supports advanced parameters such as custom **Signature Endorsement Policies** and **Private Data Collections (Scenario s4 & s5)**, which are not completely supported in Fablo.

---


## 📁 Repository Structure

```
├── baseline/                        # Manual deployment files & helper scripts
│   └── s1 to s5/
├── fablo/                           # Fablo configuration specs
│   └── s1 to s5/
├── fabric-network-orchestrator/     # Fabric Network Orchestrator (FNO) workspace
│   ├── fno.exe                      # Compiled FNO CLI executable
│   ├── invalid-configurations/      # YAML specs containing violations (tests)
│   └── s1 to s5/                    # Benchmark scenario configurations for FNO
├── cloc-2.08.exe                    # CLOC executable used to measure Lines of Code
├── cloc.sh                          # Shell script to automatically run the CLOC benchmark
└── README.md                        # Project documentation (this file)
```

---

## 🚀 Getting Started & Execution

### 1. Run the LoC Comparison Benchmark
To compute the LoC comparison table on a Bash environment:
```bash
./cloc.sh
```

*(Note: Ensure line endings on the script are LF or run it via PowerShell).*

### 2. Run the FNO CLI
The pre-compiled `fno.exe` utility is included in the `fabric-network-orchestrator` folder. 

#### A. Generate Deployment Artifacts
Generate standard cryptogen, configtx, and docker-compose files without spinning up the containers:
```bash
cd fabric-network-orchestrator
./fno.exe artifacts generate -c ./s1/config.yml
```
This writes all generated network configurations into the output folder specified inside the `config.yml` (e.g., `c1/output/fno-s1/`).

#### B. Deploy a Live Network
Deploys the network fully, generating the cryptogen configs, genesis blocks, starting docker containers, creating channels, and joining peers automatically:
```bash
./fno.exe network deploy -c ./s1/config.yml
```

#### C. Control Network Lifecycle
```bash
# Start existing containers
./fno.exe network up -c ./s1/config.yml

# Stop and tear down the network, clearing containers and volumes
./fno.exe network down -c ./s1/config.yml
```

#### D. Validate Constraints (Constraint Tests)
You can verify FNO's built-in validation by passing any of the invalid specification files inside `invalid-configurations` to the generate command:
```bash
# Try to generate from a duplicate org config
./fno.exe artifacts generate -c ./invalid-configurations/21-duplicate-org-name.yml
```
*Expected Output:*
```
[FATAL] Configuration validation failed!
[RULE]  R21 - Duplicate Org Name
Detail: duplicate organization name: Org1.
```
