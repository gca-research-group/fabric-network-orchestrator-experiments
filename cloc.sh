#!/usr/bin/env bash

get_loc() {
  ./cloc-2.08.exe "$1" --not-match-d='(data|output|chaincode)' --csv 2>/dev/null | tr -d '\r' | grep ",SUM," | cut -d',' -f5 || echo "0"
}

s1_b=$(( $(get_loc "baseline/s1/b-s1") + $(get_loc "baseline/s1/deploy.sh") ))
s1_fablo=$(get_loc "fablo/s1/fablo-config.yaml")
s1_fno=$(get_loc "fabric-network-orchestrator/s1/config.yml")

s2_b=$(( $(get_loc "baseline/s2/b-s2") + $(get_loc "baseline/s2/deploy.sh") ))
s2_fablo=$(get_loc "fablo/s2/fablo-config.yaml")
s2_fno=$(get_loc "fabric-network-orchestrator/s2/config.yml")

s3_b=$(( $(get_loc "baseline/s3/b-s3") + $(get_loc "baseline/s3/deploy.sh") ))
s3_fablo=$(get_loc "fablo/s3/fablo-config.yaml")
s3_fno=$(get_loc "fabric-network-orchestrator/s3/config.yml")

s4_b=$(( $(get_loc "baseline/s4/b-s4") + $(get_loc "baseline/s4/deploy.sh") ))
s4_fno=$(get_loc "fabric-network-orchestrator/s4/config.yml")

s5_b=$(( $(get_loc "baseline/s5/b-s5") + $(get_loc "baseline/s5/deploy.sh")  + $(get_loc "baseline/s5/chaincode.sh")))
s5_fablo=$(get_loc "fablo/s5/fablo-config.yaml")
s5_fno=$(get_loc "fabric-network-orchestrator/s5/config.yml")

echo ""
echo "Hyperledger Fabric Deployment - LoC Comparison Summary"
echo "----------------------------------------------------"
echo "Scenario     | Baseline | Fablo | Orchestrator"
echo "----------------------------------------------------"
printf "%-12s | %12s | %12s  | %16s\n" "Scenario s1" "$s1_b" "$s1_fablo" "$s1_fno"
printf "%-12s | %12s | %12s  | %16s\n" "Scenario s2" "$s2_b" "$s2_fablo" "$s2_fno"
printf "%-12s | %12s | %12s  | %16s\n" "Scenario s3" "$s3_b" "$s3_fablo" "$s3_fno"
printf "%-12s | %12s | %12s  | %16s\n" "Scenario s4" "$s4_b" "$s4_fablo" "$s4_fno"
printf "%-12s | %12s | %12s  | %16s\n" "Scenario s4" "$s5_b" "$s5_fablo" "$s5_fno"
echo "----------------------------------------------------"
echo ""