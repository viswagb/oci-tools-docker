docker build -f Dockerfile --compress -t oci-tools-base-docker:latest .
docker tag oci-tools-base-docker:latest docker.io/viswagb/oci-tools-base-docker:latest
docker push docker.io/viswagb/oci-tools-base-docker:latest