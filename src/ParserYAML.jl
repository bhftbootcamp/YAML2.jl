module ParserYAML

export parse_yaml,
    open_yaml

export AbstractYAMLError,
    YAMLError,
    YAMLMemoryError,
    YAMLReaderError,
    YAMLScannerError,
    YAMLParserError

using ..LibYAMLc

include("yaml_errors.jl")
include("yaml_values.jl")

const YAML_MERGE_KEY   = "<<"
const YAML_INCLUDE_TAG = "!include"

abstract type AbstractParseContext{D <: AbstractDict} end

struct FileParseContext{D} <: AbstractParseContext{D}
    dir::String
    function FileParseContext(path::AbstractString, ::Type{D}) where {D}
        dir = dirname(path)
        return new{D}(dir)
    end
end

struct DefaultParseContext{D} <: AbstractParseContext{D}
    function DefaultParseContext(::Type{D}) where {D}
        return new{D}()
    end
end

@inline function init_parser(yaml_bytes::AbstractVector{UInt8})
    parser = Ref{LibYAMLParser}()
    ok = libyaml_parser_initialize(parser)
    ok == 0 && throw_yaml_err(parser[])
    libyaml_parser_set_input_string(parser, pointer(yaml_bytes), length(yaml_bytes))
    return parser
end

@inline function cleanup_parser(parser::Ref{LibYAMLParser})
    libyaml_parser_delete(parser)
end

@inline c_array_length(start::Ptr, top::Ptr, size::Int) = (top - start) ÷ size

@inline function load_docs(parser::Ref{LibYAMLParser}, ctx::AbstractParseContext)
    result = Any[]
    while true
        doc = Ref{LibYAMLDocument}()
        ok = libyaml_parser_load(parser, doc)
        ok == 0 && throw_yaml_err(parser[])
        root_ptr = libyaml_document_get_root_node(doc)
        root_ptr == C_NULL && break
        try
            push!(result, parse_node(doc, unsafe_load(root_ptr), ctx))
        finally
            libyaml_document_delete(doc)
        end
    end
    return result
end

@inline function parse_value(tag::AbstractString, value::AbstractString)
    if tag == LIBYAML_BOOL_TAG
        return parse_bool(value)
    elseif tag == LIBYAML_INT_TAG
        return parse_int(value)
    elseif tag == LIBYAML_FLOAT_TAG
        return parse_float(value)
    elseif tag == LIBYAML_TIMESTAMP_TAG
        return parse_timestamp(value)
    elseif tag == LIBYAML_NULL_TAG || isnull_value(value)
        return parse_null(value)
    elseif tag == LIBYAML_STR_TAG
        return value
    else
        throw(YAMLError("Unknown YAML tag: $tag"))
    end
end

@inline function parse_node(
    doc::Ref{LibYAMLDocument},
    node::LibYAMLNode,
    ctx::AbstractParseContext,
)
    typ = node.type
    if typ == LIBYAML_SCALAR_NODE
        return parse_scalar(node, ctx)
    elseif typ == LIBYAML_SEQUENCE_NODE
        return parse_sequence(doc, node, ctx)
    elseif typ == LIBYAML_MAPPING_NODE
        return parse_mapping(doc, node, ctx)
    else
        throw(YAMLError("Unsupported node type: $typ"))
    end
end

@inline function parse_scalar(node::LibYAMLNode, ctx::FileParseContext)
    tag = unsafe_string(node.tag)
    val = unsafe_string(node.data.scalar.value)
    if tag == YAML_INCLUDE_TAG
        return open_yaml(joinpath(ctx.dir, val))
    end
    return parse_value(tag, val)
end

@inline function parse_scalar(node::LibYAMLNode, ::DefaultParseContext)
    tag = unsafe_string(node.tag)
    val = unsafe_string(node.data.scalar.value)
    return parse_value(tag, val)
end

@inline function parse_sequence(
    doc::Ref{LibYAMLDocument},
    node::LibYAMLNode,
    ctx::AbstractParseContext,
)
    stack = node.data.sequence.items
    len = c_array_length(stack.start, stack.top, sizeof(Cuint))
    result = Vector{Any}(undef, len)
    base = stack.start
    @inbounds for i = 1:len
        idx = unsafe_load(Ptr{Cuint}(base + (i - 1) * sizeof(Cuint)))
        child_ptr = libyaml_document_get_node(doc, idx)
        result[i] = parse_node(doc, unsafe_load(child_ptr), ctx)
    end
    return result
end

@inline function merge_anchor!(dict::AbstractDict, val::Any, node_type::UInt32)
    if node_type == LIBYAML_MAPPING_NODE
        merge!(dict, val)
    elseif node_type == LIBYAML_SEQUENCE_NODE
        for submap in val
            merge!(dict, submap)
        end
    else
        throw(YAMLError("Cannot merge node type: $node_type"))
    end
    return nothing
end

@inline function parse_mapping(
    doc::Ref{LibYAMLDocument},
    node::LibYAMLNode,
    ctx::AbstractParseContext{D},
) where {D}
    stack = node.data.mapping.pairs
    len = c_array_length(stack.start, stack.top, sizeof(LibYAMLNodePair))
    result = D()
    base = stack.start
    @inbounds for i in 1:len
        pair = unsafe_load(Ptr{LibYAMLNodePair}(base + (i - 1) * sizeof(LibYAMLNodePair)))
        key_node = unsafe_load(libyaml_document_get_node(doc, pair.key))
        key = parse_node(doc, key_node, ctx)
        val_node_ptr = libyaml_document_get_node(doc, pair.value)
        val_node = unsafe_load(val_node_ptr)
        val = parse_node(doc, val_node, ctx)
        if key == YAML_MERGE_KEY
            merge_anchor!(result, val, val_node.type)
        else
            result[key] = val
        end
    end
    return result
end

function _parse_yaml(
    ctx::AbstractParseContext,
    yaml_bytes::Vector{UInt8};
    multi::Bool = false,
)
    parser = init_parser(yaml_bytes)
    try
        docs = load_docs(parser, ctx)
        isempty(docs) && return nothing
        return multi ? docs : docs[1]
    finally
        cleanup_parser(parser)
    end
end

"""
    parse_yaml(yaml_str::String; kw...)
    parse_yaml(yaml_str::Vector{UInt8}; kw...)

Parse a YAML string or file (or vector of `UInt8`) and returns a dictionary, vector or nothing.
- If a given YAML document contains a dictionary, the parser returns a dictionary.
- If a given YAML document contains just a list of variables, the parser returns a vector.
- If a given YAML document contains no information (i.e. empty), the parser returns nothing.

If the input contains multiple documents (multi-document YAML), behavior depends on the keyword argument `multi`:
- If `multi = false` (default), only the first document is returned.
- If `multi = true`, all documents are parsed and returned as a `Vector`, preserving their individual types (dictionary, vector, or nothing).

## Keyword arguments
- `multi::Bool = false`: If YAML is multidocumental, allows the reader to choose between obtaining all documents at once or only the first one.
- `dict_type = Dict{Any,Any}`: The type of the dictionary to return.

## Examples
```julia-repl
julia> yaml_str = \"\"\"
        name: Alice
        array:
          - 1
          - 2
          - a: 3
            b: null
        dict:
          a: 1
          b:
            - w
            - d
       \"\"\";

julia> parse_yaml(yaml_str)
Dict{Any, Any}(
    "dict" => Dict{Any, Any}(
        "b" => Any["w", "d"],
        "a" => "1"
    ),
    "name" => "Alice",
    "array" => Any["1", "2", Dict{Any, Any}("b" => nothing, "a" => "3")]
)

julia> yaml_str = \"\"\"
        ---
        name: Alice
        array:
          - 1
          - 2
          - a: 3
            b: null
        dict:
          a: 1
          b:
            - w
            - d
        ---
        name: John
        array:
          - 1
          - 2
          - a: 3
            b: null
        dict:
          a: 1
          b:
            - w
            - d
       \"\"\";

julia> parse_yaml(yaml_str)
Dict{Any, Any} with 3 entries:
  "dict"  => Dict{Any, Any}("b"=>Any["w", "d"], "a"=>"1")
  "name"  => "Alice"
  "array" => Any["1", "2", Dict{Any, Any}("b"=>nothing, "a"=>"3")]

julia> parse_yaml(yaml_str, multi=true)
2-element Vector{Any}:
 Dict{Any, Any}("dict" => Dict{Any, Any}("b" => Any["w", "d"], "a" => "1"), "name" => "Alice", "array" => Any["1", "2", Dict{Any, Any}("b" => nothing, "a" => "3")])
 Dict{Any, Any}("dict" => Dict{Any, Any}("b" => Any["w", "d"], "a" => "1"), "name" => "John", "array" => Any["1", "2", Dict{Any, Any}("b" => nothing, "a" => "3")])
```
"""
function parse_yaml(
    yaml::AbstractString;
    dict_type::Type{<:AbstractDict} = Dict{Any,Any},
    kw...,
)
    yaml_bytes = Vector{UInt8}(codeunits(yaml))
    return _parse_yaml(DefaultParseContext(dict_type), yaml_bytes; kw...)
end

function parse_yaml(
    yaml_bytes::AbstractVector{UInt8};
    dict_type::Type{<:AbstractDict} = Dict{Any,Any},
    kw...,
)
    vec = Vector{UInt8}(yaml_bytes)
    return _parse_yaml(DefaultParseContext(dict_type), vec; kw...)
end

"""
    open_yaml(path::AbstractString; kw...)

Read a YAML file from a given `path` and parse it.

Keyword arguments `kw` is the same as in [parse_yaml](@ref).
"""
function open_yaml(
    path::AbstractString;
    dict_type::Type{<:AbstractDict} = Dict{Any,Any},
    kw...,
)
    filepath = abspath(path)
    isfile(filepath) || throw(YAMLError("File not found: $filepath"))
    yaml_bytes = read(filepath)
    return _parse_yaml(FileParseContext(filepath, dict_type), yaml_bytes; kw...)
end

"""
    open_yaml(io::IO; kw...)

Reads a YAML file from a given `io` and parse it.

Keyword arguments `kw` is the same as in [parse_yaml](@ref).
"""
function open_yaml(
    io::IO;
    dict_type::Type{<:AbstractDict} = Dict{Any,Any},
    kw...,
)
    yaml_bytes = read(io, UInt8)
    return _parse_yaml(DefaultParseContext(dict_type), yaml_bytes; kw...)
end

end
