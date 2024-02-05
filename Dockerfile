FROM debian:bullseye-slim
RUN apt-get update -qq \ 
    && apt-get install -y --no-install-recommends \
	build-essential \
	ca-certificates \
	git \
	libbz2-1.0 \
	libcom-err2 \
	libcrypt1 \
	libffi7 \
	libgssapi-krb5-2 \
	libk5crypto3 \
	libkeyutils1 \
	libkrb5-3 \
	libkrb5support0 \
	liblzma5 \
	libncursesw6 \
	libnsl2 \
	libreadline8 \
	libsqlite3-0 \
	libsqlite3-dev \
	libssl-dev \
	libssl1.1 \
	libtinfo6 \
	libtirpc3 \
	pkg-config \
	procps \
	unzip \
	wget \
	zlib1g \
    netcat-openbsd \
    curl
COPY entrypoint.sh /entrypoint.sh

# hydra build
RUN git clone https://github.com/vanhauser-thc/thc-hydra /src

RUN set -x \
    && apt-get update \
    && apt-get -y install \
        #libmysqlclient-dev \
        default-libmysqlclient-dev \
        libgpg-error-dev \
        #libmemcached-dev \
        #libgcrypt11-dev \
        libgcrypt-dev \
        #libgcrypt20-dev \
        #libgtk2.0-dev \
        libpcre3-dev \
        #firebird-dev \
        libidn11-dev \
        libssh-dev \
        #libsvn-dev \
        libssl-dev \
        #libpq-dev \
        make \
        curl \
        gcc \
        1>/dev/null \
    # The next line fixes the curl "SSL certificate problem: unable to get local issuer certificate" for linux/arm
    && c_rehash

# Get hydra sources and compile
RUN cd /src \
        && make clean \
        && ./configure \
        && make \
        && make install

# Make clean
RUN apt-get purge -y make gcc \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /src

# Verify hydra installation
RUN hydra -h || error_code=$? \
    && if [ ! "${error_code}" -eq 255 ]; then echo "Wrong exit code for 'hydra help' command"; exit 1; fi \
    # Unprivileged user creation
    && echo 'hydra:x:10001:10001::/tmp:/sbin/nologin' > /etc/passwd \
    && echo 'hydra:x:10001:' > /etc/group

ARG INCLUDE_SECLISTS="true"

RUN set -x \
    && if [ "${INCLUDE_SECLISTS}" = "true" ]; then \
        mkdir /tmp/seclists \
        && curl -SL "https://api.github.com/repos/danielmiessler/SecLists/tarball" -o /tmp/seclists/src.tar.gz \
        && tar xzf /tmp/seclists/src.tar.gz -C /tmp/seclists \
        && mv /tmp/seclists/*SecLists*/Passwords /opt/passwords \
        && mv /tmp/seclists/*SecLists*/Usernames /opt/usernames \
        && chmod -R u+r /opt/passwords /opt/usernames \
        && rm -Rf /tmp/seclists \
        && ls -la /opt/passwords /opt/usernames \
    ;fi

# entry point
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]