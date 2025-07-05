# LibYAML2.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bhftbootcamp.github.io/LibYAML2.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bhftbootcamp.github.io/LibYAML2.jl/dev/)
[![Build Status](https://github.com/bhftbootcamp/LibYAML2.jl/actions/workflows/Coverage.yml/badge.svg?branch=master)](https://github.com/bhftbootcamp/LibYAML2.jl/actions/workflows/Coverage.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/bhftbootcamp/LibYAML2.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bhftbootcamp/LibYAML2.jl)
[![Registry](https://img.shields.io/badge/registry-Green-green)](https://github.com/bhftbootcamp/Green)

A Julia wrapper for [libyaml](https://github.com/yaml/libyaml), providing fast and minimal YAML parsing.

## Why LibYAML2.jl?

[LibYAML.jl](https://github.com/JuliaData/LibYAML.jl) was unmaintained at the time `LibYAML2.jl` was created.

## Installation

To install LibYAML2, simply use the Julia package manager:

```julia
] add LibYAML2
```

## Usage

A basic example of parsing structured YAML data in Julia, including anchors and merge keys:

```julia
using LibYAML2

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

## Comparison of [`YAML.jl`](https://github.com/JuliaData/YAML.jl) and `LibYAML2.jl`

| Feature                                | `YAML.jl`                         | `LibYAML2.jl`                      |
|----------------------------------------|-----------------------------------|-----------------------------------|
| Implicit type parsing                  | Always                            | Only when explicitly specified    |
| YAML emission (serialization) support  | ✅                                | ❌                                |
| `!include` support                     | ❌                                | ✅                                |
| Newline handling in quoted strings     | ❌ Broken                         | ✅ Correct                         |
| Multiple top-level documents (`---`)   | ❌ (`load_all_file` broken)        | ✅                                |
| YAML 1.2 compliance                    | Limited                           | Full (via `libyaml`)              |
| Pure Julia implementation              | ✅                                | ❌ (uses `libyaml`)               |
| Performance                            | Low                               | High                              |

## Useful Links

- [libyaml](https://github.com/yaml/libyaml) – Official library repository.  
- [LibYAML_jll.jl](https://github.com/JuliaBinaryWrappers/LibYAML_jll.jl) – Julia wrapper for libyaml.

## Contributing

Contributions to LibYAML2 are welcome! If you encounter a bug, have a feature request, or would like to contribute code, please open an issue or a pull request on GitHub.
