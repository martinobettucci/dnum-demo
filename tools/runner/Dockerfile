FROM python:3.13.1-slim
# Docker rootless (sans plage subuid complète) : le bac à sable apt doit tourner en root.
RUN apt-get -o APT::Sandbox::User=root update && apt-get -o APT::Sandbox::User=root install -y --no-install-recommends curl bash git && rm -rf /var/lib/apt/lists/* && git config --system safe.directory /workspace
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY run-policies.py /usr/local/bin/run-policies
RUN chmod +x /usr/local/bin/run-policies
