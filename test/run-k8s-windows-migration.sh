#!/bin/bash

# Optional environment variables
# GCE_PD_OVERLAY_NAME: which Kustomize overlay to deploy with
# GCE_PD_DO_DRIVER_BUILD: if set, don't build the driver from source and just
#   use the driver version from the overlay
# GCE_PD_BOSKOS_RESOURCE_TYPE: name of the boskos resource type to reserve

set -o nounset
set -o errexit

export GCE_PD_VERBOSITY=9
readonly PKGDIR=${GOPATH}/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver

readonly overlay_name="${GCE_PD_OVERLAY_NAME:-stable}"
readonly boskos_resource_type="${GCE_PD_BOSKOS_RESOURCE_TYPE:-gce-project}"
readonly do_driver_build="${GCE_PD_DO_DRIVER_BUILD:-true}"
readonly deployment_strategy=${DEPLOYMENT_STRATEGY:-gce}
readonly kube_version=${GCE_PD_KUBE_VERSION:-master}
readonly test_version=${TEST_VERSION:-master}
readonly gce_zone=${GCE_CLUSTER_ZONE:-us-central1-b}
readonly feature_gates="CSIMigration=true,CSIMigrationGCE=true,ExpandCSIVolumes=true"

readonly GCE_PD_TEST_FOCUS="PersistentVolumes\sGCEPD|[V|v]olume\sexpand|\[sig-storage\]\sIn-tree\sVolumes\s\[Driver:\swindows-gcepd\]|allowedTopologies|Pod\sDisks|PersistentVolumes\sDefault"

# TODO(#167): Enable reconstructions tests

make -C "${PKGDIR}" test-k8s-integration

${PKGDIR}/bin/k8s-integration-test \
        --platform=windows --bringup-cluster=false  --teardown-cluster=false \
        --run-in-prow=true \
        --kube-feature-gates=${feature_gates} --run-in-prow=true \
        --deploy-overlay-name=${overlay_name} --service-account-file=${E2E_GOOGLE_APPLICATION_CREDENTIALS} \
        --do-driver-build=${do_driver_build} --boskos-resource-type=${boskos_resource_type} \
        --migration-test=true --test-focus=${GCE_PD_TEST_FOCUS} \
        --gce-zone=${gce_zone} --deployment-strategy=${deployment_strategy} --test-version=${test_version}

#eval "$base_cmd"
