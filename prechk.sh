#!/bin/bash

# ==============================================================================
# Script: prechk.sh
# Descrição: Automação total dos pré-requisitos para Kaspersky Container Security.
#            Inclui: Namespace, Registry Secrets, Deps K8s e Kernel Headers.
# Ambiente: Laboratório Interno (Ubuntu 24.04 / K8s v1.32.5)
# ==============================================================================

set -e


# Cores para o output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- CONFIGURAÇÕES ---
CONF_FILE="$(dirname "$0")/config"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
    echo -e "${GREEN}Configurações carregadas de $CONF_FILE${NC}"
else
    echo -e "${RED}Erro: Arquivo de configuração $CONF_FILE não encontrado.${NC}"
    exit 1
fi

# Fallback para variáveis críticas se não estiverem no config (opcional)
NAMESPACE=${NAMESPACE:-"kcs"}
DOMAIN=${DOMAIN:-"kcs.cluster.lab"}

echo -e "${BLUE}=== Iniciando Preparação Total do Ambiente KCS ===${NC}"

# Validação do IP Range do MetalLB
if [ -z "$IP_RANGE" ]; then
    echo -e "${YELLOW}Aviso: O range de IPs para o MetalLB não foi informado.${NC}"
    echo -e "${BLUE}Por que isso é necessário?${NC}"
    echo -e "O MetalLB atua como um LoadBalancer interno no seu cluster. Ele precisa de um pool de IPs"
    echo -e "livres na sua rede local para atribuir um endereço fixo à console web do KCS."
    echo -e "Sem esse range, o serviço ficará em estado <Pending> e você não conseguirá acessar a interface."
    echo -ne "\n${YELLOW}Por favor, insira o range desejado (ex: 172.16.3.1-172.16.3.51): ${NC}"
    read IP_RANGE
    if [ -z "$IP_RANGE" ]; then
        echo -e "${RED}Erro: O range de IPs é obrigatório para continuar.${NC}"
        exit 1
    fi
fi

# 1. Preparação do Namespace e Secret
echo -e "${YELLOW}[1/6] Configurando Namespace e Autenticação Registry...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo -e "Criando secret kcs-registry-secret..."
kubectl create secret docker-registry kcs-registry-secret \
  --docker-server=$REGISTRY_SERVER \
  --docker-username=$REGISTRY_USER \
  --docker-password=$REGISTRY_PASS \
  --docker-email=$REGISTRY_EMAIL \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. Dependências de Infraestrutura (Cert-Manager, Storage, Metrics)
echo -e "${YELLOW}[2/6] Instalando Dependências de Infraestrutura...${NC}"

# Cert-Manager
helm repo add jetstack https://charts.jetstack.io --force-update > /dev/null
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true --wait

# Storage Class (Local Path)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
]'

# 3. MetalLB (Rede LoadBalancer)
echo -e "${YELLOW}[3/6] Configurando MetalLB com pool: $IP_RANGE ...${NC}"
helm repo add metallb https://metallb.github.io/metallb > /dev/null
helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace --wait

# Aguarda CRDs estabilizarem para aplicar config de IP
sleep 10
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
EOF

# 4. Ingress-Nginx
echo -e "${YELLOW}[4/6] Instalando Ingress-Nginx...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > /dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait

# 5. Kernel Headers (Essencial para Node Agent/eBPF)
echo -e "${YELLOW}[5/6] Instalando Kernel Headers (Runtime Security)...${NC}"
sudo apt update && sudo apt install linux-headers-$(uname -r) -y

# 6. Verificação Final e DNS
echo -e "${YELLOW}[6/6] Verificação Final...${NC}"
# Aguarda o IP ser atribuído pelo MetalLB ao Ingress
sleep 5
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "${GREEN}=== Setup Concluído com Sucesso! ===${NC}"
echo -e "${BLUE}Resumo do Ambiente:${NC}"
echo -e "- Namespace: $NAMESPACE"
echo -e "- Registry Secret: kcs-registry-secret"
echo -e "- MetalLB Pool: $IP_RANGE"
echo -e "- Ingress IP Detectado: $INGRESS_IP"
echo -e "- DNS Recomendado: Adicione '${INGRESS_IP} $DOMAIN' ao seu /etc/hosts"
echo -e "\n${GREEN}Pronto para o Helm Upgrade do KCS v2.1.1!${NC}"