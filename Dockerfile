# Використовуємо базовий образ Ubuntu 20.04
FROM ubuntu:20.04

# Встановлюємо змінну середовища для уникнення інтерактивних запитів
ENV DEBIAN_FRONTEND=noninteractive

# Оновлюємо пакети та встановлюємо всі необхідні залежності
RUN apt-get update && apt-get install -y \
    tzdata \
    python3 \
    python3-venv \
    python3-pip \
    libpcre2-dev \
    build-essential \
    cmake \
    g++ \
    flex \
    bison \
    libpcap-dev \
    libpcre3-dev \
    libdnet-dev \
    libdumbnet-dev \
    libluajit-5.1-dev \
    libtins-dev \
    libhwloc-dev \
    zlib1g-dev \
    pkg-config \
    libssl-dev \
    git \
    wget \
    liblzma-dev \
    libnghttp2-dev \
    uuid-dev \
    libmnl-dev \
    nano \
    vim \
    iputils-ping \
    curl \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

# Встановлюємо робочу директорію
WORKDIR /usr/local

# Завантажуємо та встановлюємо libdaq
RUN git clone https://github.com/snort3/libdaq.git /tmp/libdaq && \
    cd /tmp/libdaq && \
    ./bootstrap && \
    ./configure --prefix=/usr/local/lib/daq_s3 && \
    make && \
    make install && \
    rm -rf /tmp/libdaq

# Додаємо шлях до бібліотеки libdaq у динамічний завантажувач
RUN echo "/usr/local/lib/daq_s3/lib" | tee /etc/ld.so.conf.d/daq.conf && ldconfig

# Завантажуємо та встановлюємо libml
RUN git clone https://github.com/snort3/libml.git /tmp/libml && \
    cd /tmp/libml && \
    ./configure.sh --prefix=/usr/local/libml && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/libml 

# Повторно клонуємо libml для отримання прикладів
RUN mkdir -p /usr/local/src/libml && \
    chmod 755 /usr/local/src/libml && \
    git clone https://github.com/snort3/libml.git /usr/local/src/libml

# Додаємо шлях до бібліотеки libml у динамічний завантажувач
RUN echo "/usr/local/libml/lib" | tee /etc/ld.so.conf.d/libml.conf && ldconfig

# Завантажуємо та встановлюємо Snort3 з підтримкою libml
RUN git clone https://github.com/snort3/snort3.git /tmp/snort3 && \
    cd /tmp/snort3 && \
    ./configure_cmake.sh --prefix=/usr/local/snort \
                         --with-daq-includes=/usr/local/lib/daq_s3/include/ \
                         --with-daq-libraries=/usr/local/lib/daq_s3/lib/ \
                         --with-dnet-includes=/usr/include \
                         --with-dnet-libraries=/usr/lib \
                         --with-libml-includes=/usr/local/libml/include \
                         --with-libml-libraries=/usr/local/libml/lib \
                         --enable-debug-msgs && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/snort3

# Створюємо псевдонім для Snort із включенням шляху до директорії DAQ
RUN echo "alias snort='/usr/local/snort/bin/snort --daq-dir /usr/local/lib/daq_s3/lib/daq'" >> ~/.bashrc

# Копіюємо власні правила та скрипти
COPY local.rules /usr/local/src/libml/examples/classifier/local.rules
COPY pcapgen.py /usr/local/src/libml/examples/classifier/pcapgen.py

# Команда за замовчуванням для відкриття оболонки
CMD ["/bin/bash"]
