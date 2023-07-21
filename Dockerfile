# lts with jdk8, starting with 2.303 jdk11 is the default
FROM jenkins/jenkins:2.401.2-lts-jdk11

# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH
ARG TARGETOS

ENV VELERO_VERSION=1.7.0
ENV HELM_VERSION=v3.12.2
ENV KUBECTL_VERSION=v1.26.6

# change user to root to install some tools
USER root

RUN apt-get update -y \
    && apt-get install python3-pip python3-venv libpq-dev jq libltdl7 netcat sshpass rsync python3-mysqldb -y \
    && apt-get clean -y

COPY requirements.txt /tmp/requirements.txt

RUN pip3 install -r /tmp/requirements.txt

RUN ansible-galaxy collection install kubernetes.core:==2.2.3 ansible.utils:==2.7.0

RUN curl -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_${TARGETOS}_${TARGETARCH} -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

RUN curl -L -o /usr/bin/aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/${TARGETOS}/${TARGETARCH}/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

RUN curl -L https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o /tmp/velero-tar.gz && \
    tar xvf /tmp/velero-tar.gz && \
    mv velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}/velero /usr/local/bin && \
    rm -rf /tmp/velero-tar.gz velero-v${VELERO_VERSION}-${TARGETOS}-${TARGETARCH}

RUN curl -L -o /tmp/vault.zip \
    https://releases.hashicorp.com/vault/1.11.0/vault_1.11.0_${TARGETOS}_${TARGETARCH}.zip && \
    cd /tmp && unzip vault.zip && mv vault /usr/bin/ && \
    rm -rf /tmp/vault.zip

RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

RUN curl -o /tmp/helm.tar.gz \
      https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz && \
    tar -C /tmp -xvf /tmp/helm.tar.gz && \
    mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/helm && \
    rm -rf /tmp/linux-${TARGETARCH} && rm -rf /tmp/helm.tar.gz

# overrite install-plugins to limit concurrent downloads
COPY scripts/install-plugins.sh /usr/local/bin/install-plugins.sh

# move jenkins-plugin-cli binary in order to use the old plugin download strategy
RUN mv /bin/jenkins-plugin-cli /bin/jenkins-plugin-cli-moved
