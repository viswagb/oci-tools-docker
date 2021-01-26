FROM python:3.7.2-stretch

ARG CLI_VERSION=2.8.0
ARG BUILD_DATE
ARG VCS_REF

WORKDIR /oci-cli

ENV https_proxy=http://www-proxy-hqdc.us.oracle.com:80
ENV http_proxy=http://www-proxy-hqdc.us.oracle.com:80
ENV no_proxy=localhost,127.0.0.1,.us.oracle.com,.oraclecorp.com,.oraclevcn.com

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip

# Install OCI CLI
RUN set -ex \
    && wget -qO- -O oci-cli.zip "https://github.com/oracle/oci-cli/releases/download/v${CLI_VERSION}/oci-cli-${CLI_VERSION}.zip" \
    && unzip oci-cli.zip -d .. \
    && rm oci-cli.zip \
    && pip install oci_cli-*-py2.py3-none-any.whl
RUN yes | oci setup autocomplete

RUN rm oci_cli-*-py2.py3-none-any.whl

# Install Kubectl
# was:     && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
# use v1.17.9 to retain compatibility with current deploy scripts
RUN set -ex \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.9/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin

# Install Helm
RUN set -ex \
    && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh \
    && chmod u+x install-helm.sh \
    && ./install-helm.sh --version v2.14.3 \
    && export KUBECONFIG=$HOME/.kube/config

# Install OpenJDK-11
#RUN add-apt-repository ppa:openjdk-r/ppa && \
#    apt-get update && \
#    apt-get install -y openjdk-11-jdk && \
#    apt-get install -y ant && \
#    apt-get clean;

RUN export ESUM='99be79935354f5c0df1ad293620ea36d13f48ec3ea870c838f20c504c9668b57' && \
    export BINARY_URL='https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz' && \
    curl -LfsSo /tmp/openjdk-11.0.2_linux-x64_bin.tar.gz ${BINARY_URL} && \
    echo "${ESUM} */tmp/openjdk-11.0.2_linux-x64_bin.tar.gz" | sha256sum -c - && \
    mkdir -p /usr/lib/jvm/java-11-openjdk-x64 && \
    cd /usr/lib/jvm/java-11-openjdk-x64 && \
    tar -xf /tmp/openjdk-11.0.2_linux-x64_bin.tar.gz --strip-components=1 && \
    rm -rf /tmp/openjdk-11.0.2_linux-x64_bin.tar.gz

## Fix certificate issues
RUN apt-get install -y ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Install Maven 3
ARG MAVEN_VERSION=${MAVEN_VERSION:-3.6.0}
ENV MAVEN_VERSION=${MAVEN_VERSION}
ENV MAVEN_HOME=/usr/apache-maven-${MAVEN_VERSION}
ENV PATH=${PATH}:${MAVEN_HOME}/bin
RUN curl -sL http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s ${MAVEN_HOME} /usr/maven

# Install istioctl
RUN set -ex \
    && mkdir -p /staging/istio \
    && cd /staging/istio \
    && curl -sSfkL https://istio.io/downloadIstio | ISTIO_VERSION=1.6.0 sh \
    && ln -s /staging/istio/istio-*/bin/istioctl /usr/local/bin/istioctl \
    && chmod +x /usr/local/bin/istioctl

# Install kubens
RUN set -ex \
    && mkdir -p /staging/kubens \
    && cd /staging/kubens \
    && curl -sSfkLO https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens \
    && ln -s /staging/kubens/kubens /usr/local/bin/kubens \
    && chmod +x /usr/local/bin/kubens

# Install kubectx
RUN set -ex \
    && mkdir -p /staging/kubectx \
    && cd /staging/kubectx \
    && curl -sSfkLO https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx \
    && ln -s /staging/kubectx/kubectx /usr/local/bin/kubectx \
    && chmod +x /usr/local/bin/kubectx

CMD ["/bin/bash"]