#!/bin/bash
# ------------------------------------------------------------------------------
# KCS POC - Deploy Watch Logic (Bash Reference)
# This snippet provides the logic for the "Watch and Exit" feature.
# ------------------------------------------------------------------------------

NAMESPACE="kcs"
TIMEOUT=900 # 15 minutes
START_TIME=$(date +%s)

echo "--- MONITORING KCS DEPLOYMENT ---"

while true; do
    # Get pod status: Name, Ready Condition, and Phase
    PODS_STATUS=$(kubectl get pods -n $NAMESPACE --no-headers)
    
    # Calculate totals
    TOTAL_PODS=$(echo "$PODS_STATUS" | wc -l)
    READY_PODS=$(echo "$PODS_STATUS" | grep "Running" | grep -v "0/" | wc -l)
    COMPLETED_JOBS=$(echo "$PODS_STATUS" | grep "Completed" | wc -l)
    
    STABLE_COUNT=$((READY_PODS + COMPLETED_JOBS))

    # Clear line and print progress
    echo -ne "\rProgress: $STABLE_COUNT/$TOTAL_PODS pods are stable... "

    # Check if all pods are stable
    if [ "$STABLE_COUNT" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        echo -e "\n\n[SUCCESS] All KCS components are Running!"
        # Update namespace label to stable
        kubectl label ns $NAMESPACE kcspoc.io/status=stable --overwrite > /dev/null
        break
    fi

    # Check for timeout
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    if [ "$ELAPSED" -gt "$TIMEOUT" ]; then
        echo -e "\n\n[TIMEOUT] Deployment taking too long. Check for 'Init' errors."
        kubectl label ns $NAMESPACE kcspoc.io/status=failed --overwrite > /dev/null
        exit 1
    fi

    sleep 5
done