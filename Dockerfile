FROM ubuntu:20.04 AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
	&& ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

RUN apt-get update && apt-get install -y \
	build-essential \
	cmake \
	curl \
	git \
	libglew-dev \
	libx11-dev \
	liblua5.1-0-dev \
	libluajit-5.1-dev \
	libncurses5-dev \
	libopenal-dev \
	libssl-dev \
	libvorbis-dev \
	mercurial \
	tar \
	unzip \
	zip \
	zlib1g-dev \
	&& dpkg-reconfigure --frontend noninteractive tzdata \
	&& apt-get clean && apt-get autoclean

WORKDIR /opt
RUN git clone https://github.com/microsoft/vcpkg
RUN ./vcpkg/bootstrap-vcpkg.sh

WORKDIR /opt/vcpkg
COPY vcpkg.json /opt/vcpkg/
RUN /opt/vcpkg/vcpkg --feature-flags=binarycaching,manifests,versions install

COPY ./ /otclient/

RUN apt-get install -y libluajit-5.1-dev

WORKDIR /otclient/build/
RUN cmake -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake ..
RUN make -j$(nproc)

FROM ubuntu:20.04

RUN apt-get update; \
	apt-get install -y \
	libglew2.1 \
	libopenal1 \
	libopengl0 \
	&& apt-get clean && apt-get autoclean

COPY --from=builder /otclient/build/bin/otclient /otclient/bin/otclient
COPY ./data/ /otclient/data/.
COPY ./mods/ /otclient/mods/.
COPY ./modules/ /otclient/modules/.
COPY ./init.lua /otclient/.
WORKDIR /otclient
CMD ["./bin/otclient"]
