# Minimal container for CI testing of eic-shell launcher scripts.
# Matches the entrypoint and eic-shell scripts from eic/containers:
# https://github.com/eic/containers/tree/master/containers/eic
FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash coreutils grep && \
    rm -rf /var/lib/apt/lists/*

RUN echo 'export EIC_ENV_LOADED=1' > /etc/eic-env.sh && \
    mkdir -p /opt/local/bin /opt/local/sbin

# In-container entrypoint replicating /opt/local/sbin/entrypoint.sh in eic/containers
RUN <<'EOF'
cat << 'SH' > /opt/local/sbin/entrypoint.sh
#!/usr/bin/env bash
. /etc/eic-env.sh
exec "$@"
SH
chmod +x /opt/local/sbin/entrypoint.sh
EOF

# In-container eic-shell replicating /opt/local/bin/eic-shell in eic/containers
RUN <<'EOF'
cat << 'SH' > /opt/local/bin/eic-shell
#!/usr/bin/env bash
piped_args=()
if [ -p /dev/stdin ]; then
  while IFS= read -r line; do
    piped_args+=("${line}")
  done
fi
. /etc/eic-env.sh
if [ "${#piped_args[@]}" != "0" ]; then
  printf "%s\n" "${piped_args[@]}" | bash -s -- --norc --noprofile
elif [ $# -gt 0 ]; then
  exec bash -c "$@"
else
  exec bash --norc --noprofile
fi
SH
chmod +x /opt/local/bin/eic-shell
EOF

RUN ln -sf /opt/local/bin/eic-shell /usr/local/bin/eic-shell
ENV PATH=/opt/local/bin:$PATH
ENTRYPOINT ["/opt/local/sbin/entrypoint.sh"]
