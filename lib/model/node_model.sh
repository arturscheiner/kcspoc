#!/bin/bash

# ==============================================================================
# Layer: Model
# File: node_model.sh
# Responsibility: Node-level resource data and Deep Inspection probe pods
# ==============================================================================

# Returns: name|labels|cpu_a|cpu_c|mem_a|mem_c|disk_a|disk_c
model_node_get_raw_baseline_data() {
    kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}|{.metadata.labels}|{.status.allocatable.cpu}|{.status.capacity.cpu}|{.status.allocatable.memory}|{.status.capacity.memory}|{.status.allocatable.ephemeral-storage}|{.status.capacity.ephemeral-storage}{"\n"}{end}'
}

model_node_get_global_totals() {
    local cpu=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.cpu}{"\n"}{end}' | awk '{s+=$1} END {print s}')
    local mem_ki=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.memory}{"\n"}{end}' | sed 's/Ki//g' | awk '{s+=$1} END {print s}')
    local mem_gb=$((mem_ki / 1024 / 1024))
    echo "$cpu|$mem_gb"
}

model_node_deploy_probe_pod() {
    local name="$1"
    local ns="$2"
    local target_node="$3"
    local pod_file="$4"

    cat <<EOF > "$pod_file"
apiVersion: v1
kind: Pod
metadata:
  name: ${name}
  namespace: ${ns}
spec:
  hostPID: true
  hostIPC: true
  hostNetwork: true
  nodeName: ${target_node}
  restartPolicy: Never
  tolerations:
  - operator: "Exists"
  containers:
  - name: debug-container
    image: ubuntu:latest
    command: ["sleep", "infinity"]
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /host
      name: host-volume
  volumes:
  - name: host-volume
    hostPath:
      path: /
  terminationGracePeriodSeconds: 1
EOF
    kubectl apply -f "$pod_file" -n "$ns" &>> "$DEBUG_OUT"
}

model_node_wait_probe_pod() {
    local name="$1"
    local ns="$2"
    local timeout="${3:-15s}"
    kubectl wait --for=condition=Ready pod/"$name" -n "$ns" --timeout="$timeout" &>> "$DEBUG_OUT"
}

model_node_exec_probe() {
    local name="$1"
    local ns="$2"
    shift 2
    kubectl exec "$name" -n "$ns" -- "$@"
}

model_node_delete_probe_pod() {
    local name="$1"
    local ns="$2"
    kubectl delete pod "$name" -n "$ns" --force --grace-period=0 &>> "$DEBUG_OUT"
}
