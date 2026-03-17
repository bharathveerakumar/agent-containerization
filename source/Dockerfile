FROM ubuntu:24.04

MAINTAINER site24x7<support@site24x7.com>

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --reinstall ca-certificates ubuntu-keyring && \
  apt-get install -y python3 python3-dev python3-venv && \
  apt-get install -y wget && \
  apt-get install -y vim && \
  apt-get install -y libssl-dev && \
  apt-get install -y tini && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /etc/site24x7-init-config/

RUN wget https://bootstrap.pypa.io/get-pip.py \
 && python3 get-pip.py --break-system-packages \
 && rm get-pip.py

COPY ["s247_setup.sh", "entrypoint.sh", "requirements.txt", "heartbeat.sh", "./"]

RUN chmod +x entrypoint.sh && chmod +x s247_setup.sh && chmod +x heartbeat.sh

RUN ./s247_setup.sh

HEALTHCHECK --interval=20s --timeout=3s --retries=3 \
  CMD /etc/site24x7-init-config/heartbeat.sh

RUN useradd -ms /bin/bash site24x7

RUN chown -R site24x7:site24x7 /opt

USER site24x7

WORKDIR /opt

ENTRYPOINT ["tini", "--", "/etc/site24x7-init-config/entrypoint.sh"]

CMD ["bash", "-c", "while true; do sleep 300; done"]
