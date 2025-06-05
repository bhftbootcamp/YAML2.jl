# LibYAML.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bhftbootcamp.github.io/LibYAML.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bhftbootcamp.github.io/LibYAML.jl/dev/)
[![Build Status](https://github.com/bhftbootcamp/LibYAML.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/bhftbootcamp/LibYAML.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/bhftbootcamp/LibYAML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bhftbootcamp/LibYAML.jl)
[![Registry](https://img.shields.io/badge/registry-General-4063d8)](https://github.com/JuliaRegistries/General)

A Julia wrapper for [libyaml](https://github.com/yaml/libyaml), providing fast and minimal YAML parsing.

## Installation

To install LibYAML, simply use the Julia package manager:

```julia
] add LibYAML
```

## Usage

A basic example of parsing structured YAML data in Julia, including anchors and merge keys:

```julia
using LibYAML

yaml_config = """
defaults: &defaults
  port: !!int 443
  enable_tls: true

server:
  <<: *defaults
  bind_address: "0.0.0.0"
  tls:
    cert_file: "/etc/certs/cert_file.pem"
    key_file: "/etc/certs/key_file.pem"

metrics:
  prometheus_enabled: true
  listen: "0.0.0.0:9100"
  service_labels: {service: "secure-backend"}

role_defaults: &role_defaults
  permissions:
    - read
    - write

users:
  - username: "admin"
    <<: *role_defaults
  - username: "stanislav"
    <<: *role_defaults
    permissions:
      - read
"""

julia> parse_yaml(yaml_config)
Dict{String, Any} with 5 entries:
  "metrics" => Dict{String,Any}("listen"=>"0.0.0.0:9100", …)
  "users"   => Any[...]
  ...
```

## Useful Links

- [libyaml](https://github.com/yaml/libyaml) – Official library repository.  
- [LibYAML_jll.jl](https://github.com/JuliaBinaryWrappers/LibYAML_jll.jl) – Julia wrapper for libyaml.

## Contributing

Contributions to LibYAML are welcome! If you encounter a bug, have a feature request, or would like to contribute code, please open an issue or a pull request on GitHub.
