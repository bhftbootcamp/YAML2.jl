# LibYAML.jl 

Julia wrapper package for parsing `yaml` files

## Installation

To install LibYAML, simply use the Julia package manager:

```julia
] add LibYAML
```

## Usage
```julia
using LibYAML

yaml_str = """
retCode: 0
retMsg: "OK"
result:
  ap: 0.6636
  bp: 0.6634
  h: 0.6687
  l: 0.6315
  lp: 0.6633
  o: 0.6337
  qv: 1.1594252877069e7
  s: "ADAUSDT"
  t: "2024-03-25T19:05:35.491"
  v: 1.780835204e7
retExtInfo: {}
time: "2024-03-25T19:05:38.912"
"""

julia> parse_yaml(yaml_str)
Dict{String, Any} with 5 entries:
  "retExtInfo" => Dict{String, Any}()
  "time"       => "2024-03-25T19:05:38.912"
  "retCode"    => "0"
  "retMsg"     => "OK"
  "result"     => Dict{String, Any}("v"=>"1.780835204e7", "ap"=>"0.6636", "o"=>"0.6337", "t"=>"2024-03-25T19:05:35.491", "qv"=>"1.15942…
```

## Useful Links

- [libyaml](https://github.com/yaml/libyaml) – Official library repository.  
- [LibYAML_jll.jl](https://github.com/JuliaBinaryWrappers/LibYAML_jll.jl) – Julia wrapper for libyaml.
