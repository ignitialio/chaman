#!/bin/sh

# ------------------------------------------------------------------------------
# Generate app configuration
# ------------------------------------------------------------------------------
# generates app configuration into kustomization folder for k8s ConfigMap deploy
iio config -i k8s/config -o k8s/kustomizations/config app generate

# ------------------------------------------------------------------------------
# Kustomize
# ------------------------------------------------------------------------------
# cutomize deploy with previous generated config map (creates ConfigMap)
kubectl --kubeconfig ${IIOS_K8S_KUBECONFIG_PATH} apply -k k8s/kustomizations

# ------------------------------------------------------------------------------
# Generate deploy configuration
# ------------------------------------------------------------------------------
# generates K8S receipes
iio config deploy generate

# ------------------------------------------------------------------------------
# Deploy
# ------------------------------------------------------------------------------
# apply receipes and starts app pods (deployments, services, ...)
kubectl --kubeconfig ${IIOS_K8S_KUBECONFIG_PATH} apply -f k8s/deploy
