# To build this image from this folder with OpenFOAM v2206:
# docker build --build-arg OPENFOAM_VERSION=2206 -f base.dockerfile -t of-unit-testing-paper:2206-base .
#
# Builds on Ubuntu 22.04 LTS to provide ESI (OpenCFD) OpenFOAM in Opt mode
# using system OpenMPI. The specifc OpenFOAM version is passed as a build arg.
#
# The built containers are ready to power Docker clusters/Swarms
# and to be used in CI environments (Github actions specifically)


FROM ubuntu:22.04
LABEL maintainer="Mohammed Elwardi Fadeli <elwardi.fadeli@tu-darmstadt.de>"
LABEL source="https://github.com/FoamScience/of-unit-testing-paper/blob/main/docker/dockerfile"

# Base env. vars.
ENV DEBIAN_FRONTEND=noninteractive
ARG OPENFOAM_VERSION
ENV SHELL=/usr/bin/bash

# ------------------------------------------------------------
# Install Packages
# ------------------------------------------------------------

# Install basic requirements
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        sudo apt-utils vim curl software-properties-common \
        git-core cmake openssh-server python3-dev gcc g++  \
        binutils libopenmpi-dev openmpi-bin openmpi-common \
        openmpi-doc

# Set up OpenFOAM repositories
RUN sh -c "curl https://dl.openfoam.com/add-debian-repo.sh | bash"

# Install OpenFOAM
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openfoam${OPENFOAM_VERSION}-default && \
    apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------
# Add an 'openfoam' user with root access
# ------------------------------------------------------------

ENV USER openfoam
ENV HOME=/home/${USER} 
ENV SSHDIR ${HOME}/.ssh/
RUN adduser --disabled-password --gecos "" ${USER} -u 1001 && \
    echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# ------------------------------------------------------------
# SSH mess
# ------------------------------------------------------------

RUN mkdir /var/run/sshd
RUN echo 'root:${USER}' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off right after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN mkdir -p ${SSHDIR}
ADD ssh/config ${SSHDIR}/config
ADD ssh/id_rsa.of ${SSHDIR}/id_rsa
ADD ssh/id_rsa.of.pub ${SSHDIR}/id_rsa.pub
ADD ssh/id_rsa.of.pub ${SSHDIR}/authorized_keys

RUN chmod -R 600 ${SSHDIR}* && \
    chown -R ${USER}:${USER} ${SSHDIR}

# ------------------------------------------------------------
# Configure MPI and set ownership on ~/data folder
# ------------------------------------------------------------

RUN echo "source /usr/lib/openfoam/openfoam${OPENFOAM_VERSION}/etc/bashrc" >> /home/${USER}/.bashrc
RUN rm -fr ${HOME}/.openmpi && mkdir -p ${HOME}/.openmpi
RUN chown -R ${USER}:${USER} ${HOME}/.openmpi
RUN mkdir ${HOME}/data
RUN chown -R ${USER}:${USER} ${HOME}/data

# ------------------------------------------------------------
# Final preparations
# ------------------------------------------------------------

WORKDIR ${HOME}/data
EXPOSE 22
USER root
RUN apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN /usr/bin/ssh-keygen -A 
COPY bin/ ${HOME}/bin/
ENV PATH="${HOME}/bin:${PATH}"
USER openfoam
WORKDIR ${HOME}

ENTRYPOINT [ "uid_entrypoint" ]
CMD run
