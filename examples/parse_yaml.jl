#__ parse_yaml

using LibYAML2

yaml_config = """
server:
  bind_address: "0.0.0.0"
  port: 443
  enable_tls: true
  tls:
    cert_file: "/etc/certs/fullchain.pem"
    key_file: "/etc/certs/privkey.pem"
    client_auth: "optional"

security:
  csp_enabled: true
  rate_limit_per_minute: 1000
  ip_whitelist:
    - "10.0.0.0/8"
    - "192.168.0.0/16"
  jwt:
    secret: "securekeyhere"
    issuer: "secure-backend"
    audience: "clients"
    exp: 1800

audit:
  enabled: true
  output: "/var/log/audit.log"
  rotate_daily: true
  redact_fields:
    - password
    - token

logging:
  level: "warn"
  output: "stdout"
  format: "json"

metrics:
  prometheus_enabled: true
  listen: "0.0.0.0:9100"
  path: "/metrics"
  service_labels:
    service: "secure-backend"
    environment: "production"
  pprof_enabled: true
  tracing_sample_rate: 0.05
"""

parse_yaml(yaml_config)
