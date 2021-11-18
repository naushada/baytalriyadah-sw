FROM ubuntu:focal
ENV TZ=Asia/Calcutta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
RUN apt-get install -y --no-install-recommends \
    ca-cacert \
    cmake \
    build-essential \
    libboost-all-dev \
    libssl-dev \
    wget \
    zlib1g-dev

# get and build ACE
WORKDIR /root
RUN wget https://github.com/DOCGroup/ACE_TAO/releases/download/ACE%2BTAO-7_0_0/ACE+TAO-7.0.0.tar.gz
RUN tar -xzvf ACE+TAO-7.0.0.tar.gz
ENV ACE_SRC=/root/ACE_wrappers ACE_PREFIX=/usr/local/ACE_TAO-7.0.0
RUN echo '#include "ace/config-linux.h"' > ACE_wrappers/ace/config.h
RUN echo 'include $(ACE_SRC)/include/makeinclude/platform_linux.GNU' > $ACE_SRC/include/makeinclude/platform_macros.GNU
WORKDIR /root/ACE_wrappers
RUN make install INSTALL_PREFIX=${ACE_PREFIX} ACE_ROOT=${ACE_SRC}
RUN ldconfig

RUN apt-get -y install libboost-all-dev
RUN apt-get -y install libbson-dev
RUN apt-get -y install libzstd-dev

RUN apt-get -y install git
WORKDIR /root/mongo-c
RUN apt-get -y install mongodb-server-core
RUN git clone -b r1.19 https://github.com/mongodb/mongo-c-driver.git
RUN cd mongo-c-driver
WORKDIR /root/mongo-c/mongo-c-driver/build
RUN cmake ..
RUN make && make install

WORKDIR /root/mongo-cxx
RUN git clone -b releases/v3.5 https://github.com/mongodb/mongo-cxx-driver.git
RUN cd mongo-cxx-driver

WORKDIR /root/mongo-cxx/mongo-cxx-driver/build
RUN cmake ..  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
RUN make && make install
RUN ldconfig

WORKDIR /root
RUN git clone https://github.com/naushada/granada.git
RUN cd granada
RUN mkdir ix86_64x
WORKDIR /root/granada/ix86_64x
RUN cmake .. && make

#node installation
#FROM node:latest AS gui-build
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install build-essential
#RUN apt-get -y install nodejs npm

WORKDIR /root
RUN mkdir webgui && cd webgui
RUN mkdir webclient && cd webclient

WORKDIR /root/webgui/webclient
RUN git clone https://github.com/naushada/baytalriyadah.git
RUN cd baytalriyadah


########## installing dependencies node_module ######################
RUN apt-get -y install curl
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get -y install nodejs

WORKDIR /root/webgui/webclient/baytalriyadah

RUN npm install
RUN npm update 
######## copy some packages from local to container ##############################


##### Compile the Angular webgui #################
RUN npm install -g @angular/cli

WORKDIR /root/webgui/webclient/baytalriyadah
RUN ng build --configuration production --aot --base-href /bayt/

RUN cd /opt
RUN mkdir bayt
RUN cd bayt
RUN mkdir webgui
RUN cd webgui
WORKDIR /opt/bayt/webgui
RUN cp -r /root/webgui/webclient/baytalriyadah/dist/ui .

WORKDIR /opt/bayt
RUN mkdir granada
RUN cd granada
WORKDIR /opt/bayt/granada

# copy from previoud build stage
RUN cp /root/granada/ix86_64x/uniservice .

# CMD_ARGS will be : --server-ip <ip> --server-port <port>  --server-worker <number of worker> --mongo-db-name <name> --mongo-db-connection-pool <conn-pool> --mongo-db-uri <uri>
ENV ARGS="--server-worker 5"
ENV PORT=8080
CMD "/opt/bayt/granada/uniservice" --server-port ${PORT} ${ARGS}
