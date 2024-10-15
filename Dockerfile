ARG NAEMON_VERSION="1.4.2"
ARG UBUNTU_VERSION="noble"

FROM ubuntu:${UBUNTU_VERSION} AS build
ARG APT_PROXY
WORKDIR /build
# Create an apt proxy configuration
RUN if [ -n "$APT_PROXY" ]; then \
        echo "Acquire::http::Proxy \"$APT_PROXY\";" > /etc/apt/apt.conf.d/01proxy; \
    fi
RUN apt update -y && apt install -y \
	build-essential \
	curl \
	autoconf \
	libtool \
	libglib2.0-dev \
	help2man \
	gperf
ARG NAEMON_VERSION
RUN cd /build && \
	curl -sSL -o naemon-core-v${NAEMON_VERSION}.tar.gz https://github.com/naemon/naemon-core/archive/refs/tags/v${NAEMON_VERSION}.tar.gz && \
	tar -xzf naemon-core-v${NAEMON_VERSION}.tar.gz && \
	cd /build/naemon-core-${NAEMON_VERSION} && \
	./autogen.sh && \
	./configure --prefix="" --exec-prefix=/usr --localstatedir=/var/lib/naemon --runstatedir=/run/naemon --includedir=/usr/include --datarootdir=/usr/share --with-tempdir=/var/cache/naemon --with-checkresultdir=/var/cache/naemon/checkresults --with-lockfile=/run/naemon/naemon.pid --with-logdir=/var/log/naemon && \
	make -j"$(nproc)" && \
	mkdir -p /build/target && \
	DESTDIR=/build/target make install && \
	rm -r /build/target/etc/naemon/conf.d/printer.cfg && \
	rm -r /build/target/etc/naemon/conf.d/switch.cfg && \
	rm -r /build/target/etc/naemon/conf.d/windows.cfg
COPY templates/naemon.cfg /build/target/etc/naemon/naemon.cfg
RUN cd /build && \
	curl -sSL -o naemon-livestatus-v${NAEMON_VERSION}.tar.gz https://github.com/naemon/naemon-livestatus/archive/refs/tags/v${NAEMON_VERSION}.tar.gz && \
	tar -xzf naemon-livestatus-v${NAEMON_VERSION}.tar.gz && \
	cd /build/naemon-livestatus-${NAEMON_VERSION} && \
	NAEMON_CFLAGS="-I/build/target/usr/include -I/usr/include -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include" NAEMON_LIBS="-L/build/target/usr/lib -L/usr/lib -lnaemon -ldl -lm -lglib-2.0" ./autogen.sh && \
	NAEMON_CFLAGS="-I/build/target/usr/include -I/usr/include -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include" NAEMON_LIBS="-L/build/target/usr/lib -L/usr/lib -lnaemon -ldl -lm -lglib-2.0" ./configure --prefix="" --exec-prefix=/usr --localstatedir=/var/lib/naemon --runstatedir=/run/naemon --includedir=/usr/include --datarootdir=/usr/share --with-tempdir=/var/cache/naemon --with-checkresultdir=/var/cache/naemon/checkresults --with-lockfile=/run/naemon/naemon.pid --with-logdir=/var/log/naemon && \
	make -j"$(nproc)" && \
	mkdir -p /build/target && \
	DESTDIR=/build/target make install && \
	mkdir -p /build/target/etc/naemon/module-conf.d && \
	rm -rf /var/lib/apt/lists/*
COPY templates/livestatus.cfg /build/target/etc/naemon/module-conf.d/livestatus.cfg

FROM ubuntu:${UBUNTU_VERSION} AS final
ARG APT_PROXY
RUN groupadd -g 999 naemon && \
	useradd -c "naemon user" -g 999 -M -d /var/lib/naemon -s /bin/false -u 999 naemon
# Create an apt proxy configuration
RUN if [ -n "$APT_PROXY" ]; then \
        echo "Acquire::http::Proxy \"$APT_PROXY\";" > /etc/apt/apt.conf.d/01proxy; \
    fi
RUN apt update -y  && apt install -y \
	libglib2.0-bin \
	monitoring-plugins \
	monitoring-plugins-contrib  && \
	rm -rf /var/lib/apt/lists/*
COPY --from=build /build/target/etc /etc
COPY --from=build /build/target/usr /usr
COPY --from=build /build/target/var /var
RUN mkdir -p /var/lib/naemon && \
	chown -R 999:999 /etc/naemon \
	/var/lib/naemon \
	/var/cache/naemon \
	/var/log/naemon && \
	mkdir -p /usr/lib/naemon && \
	ln -s /usr/lib/nagios/plugins /usr/lib/naemon/plugins
WORKDIR /var/lib/naemon
VOLUME /var/lib/naemon /var/cache/naemon /var/log/naemon
EXPOSE 6666
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER 999
ENTRYPOINT [ "/entrypoint.sh" ]
