# VERSION 1.13.2
# AUTHOR: Saverio "Kaspar" Ferrara
# DESCRIPTION: Basic Nifi application with security patches
# BUILD: docker build --rm -t <repos>/dm3-nifi:<tag> .
# EG: docker build --rm -i -t 229747392762.dkr.ecr.eu-west-1.amazonaws.com/dm3-nifi:1.13.2 .
# PUSH: docker push <repos>/dm3-nifi:<tag>

# Build the custom NARs
FROM apache/nifi:1.22.0

# Switch to root
USER 0

# AS - install Python
RUN apt-get --allow-releaseinfo-change update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libsqlite3-dev \
        libreadline-dev \
        libffi-dev \
        curl \
        libbz2-dev \
        vim \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# RUN needed commands
RUN cd /opt \
        && curl -O https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tar.xz \
        && tar -xf Python-3.8.5.tar.xz \
        && cd Python-3.8.5 \
        && ./configure --enable-optimizations \
        && make altinstall \
        && python3.8 -V \
        && cd .. \
        && rm Python-3.8.5.tar.xz


# Switch back to normal user
USER nifi

# AS - install Python's packages
RUN python3.8 -m pip install --user \
     pandas==1.3.2 \
     googleads \
     DateTime \
     pytz \
     pytz \
     requests   
# EOF