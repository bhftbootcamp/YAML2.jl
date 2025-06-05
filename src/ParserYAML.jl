module ParserYAML

using ..LibYAML
using Dates

include("errors.jl")
include("value_parsers.jl")

export parse_yaml,
    open_yaml,
    YAMLError,
    YAMLMemoryError,
    YAMLReaderError,
    YAMLScannerError,
    YAMLParserError

#__ YAML contexts __#

abstract type AbstractParserContext end

struct FileContext <: AbstractParserContext
    dir::String
    FileContext(path::AbstractString) = new(dirname(path))
end

struct DefaultContext <: AbstractParserContext end

#__ YAML parsers __#

@inline function init_parser(yaml_str::AbstractVector{UInt8})
    parser_ref = Ref{YAMLParser}()
    success = yaml_parser_initialize(parser_ref)
    success == 0 && throw_yaml_err(parser_ref[])
    yaml_parser_set_input_string(parser_ref, pointer(yaml_str), sizeof(yaml_str))

    return parser_ref
end

@inline function parse_documents(parser_ref::Ref{YAMLParser}, ctx::AbstractParserContext)
    docs = Any[]

    while true
        doc_ref = Ref{YAMLDocument}()

        success = yaml_parser_load(parser_ref, doc_ref)
        success == 0 && throw_yaml_err(parser_ref[])

        root = yaml_document_get_root_node(doc_ref)
        root == C_NULL && break

        try
            res = parse_node(doc_ref, root, ctx)
            push!(docs, res)
        finally
            yaml_document_delete(doc_ref)
        end
    end

    return docs
end

function parse_yaml_file(path::AbstractString; multi::Bool = false)
    abs_path = abspath(path)
    isfile(abs_path) || throw(YAMLError("File not found: $abs_path"))
    return parse_yaml_str(FileContext(abs_path), read(abs_path); multi = multi)
end

function parse_yaml_str(
    ctx::AbstractParserContext,
    yaml_str::AbstractVector{UInt8};
    multi::Bool,
)
    parser_ref = init_parser(yaml_str)
    try
        docs = parse_documents(parser_ref, ctx)
        isempty(docs) && return docs
        return multi ? docs : docs[1]
    finally
        yaml_parser_delete(parser_ref)
    end
end

@inline function parse_node(
    doc_ref::Ref{YAMLDocument},
    node_ptr::Ptr{YAMLNode},
    ctx::AbstractParserContext,
)
    node = unsafe_load(node_ptr)
    node_type = node.type

    if node_type == YAML_SCALAR_NODE
        return parse_scalar(node, ctx)
    elseif node_type == YAML_SEQUENCE_NODE
        return parse_sequence(doc_ref, node, ctx)
    elseif node_type == YAML_MAPPING_NODE
        return parse_mapping(doc_ref, node, ctx)
    end

    throw(YAMLError("Unsupported node type: $node_type"))
end

@inline function parse_value(value, tag)
    if tag == YAML_BOOL_TAG
        return parse_bool(value)
    elseif tag == YAML_INT_TAG
        return parse_int(value)
    elseif tag == YAML_FLOAT_TAG
        return parse_float(value)
    elseif tag == YAML_TIMESTAMP_TAG
        return parse_timestamp(value)
    elseif tag == YAML_NULL_TAG || value in NULL_KEY_WORDS # Special case to parse if user didn't specify `!!null` tag.
        return parse_null(value)
    elseif tag == YAML_STR_TAG
        return value
    end

    throw(YAMLError("Unknown YAML tag: $tag"))
end

@inline function parse_scalar(node::YAMLNode, ctx::FileContext)
    tag = unsafe_string(node.tag)
    value = unsafe_string(node.data.scalar.value)
    tag == "!include" && return parse_yaml_file(joinpath(ctx.dir, value))

    return parse_value(value, tag)
end

@inline function parse_scalar(node::YAMLNode, ::DefaultContext)
    tag = unsafe_string(node.tag)
    value = unsafe_string(node.data.scalar.value)

    return parse_value(value, tag)
end

@inline function parse_sequence(
    doc_ref::Ref{YAMLDocument},
    node::YAMLNode,
    ctx::AbstractParserContext,
)
    items = node.data.sequence.items
    len = c_array_length(items.start, items.top, sizeof(Cuint))

    items_ptr = items.start
    yaml_arr = Vector{Any}(undef, len)
    @inbounds for i = 1:len
        idx_ptr = items_ptr + (i - 1) * sizeof(Cuint)
        idx = unsafe_load(idx_ptr)
        yaml_arr[i] = parse_node(doc_ref, yaml_document_get_node(doc_ref, idx), ctx)
    end

    return yaml_arr
end

@inline function parse_mapping(
    doc_ref::Ref{YAMLDocument},
    node::YAMLNode,
    ctx::AbstractParserContext,
)
    pairs = node.data.mapping.pairs
    len = c_array_length(pairs.start, pairs.top, sizeof(YAMLNodePair))

    pairs_ptr = pairs.start
    yaml_dict = Dict{String,Any}()
    @inbounds for i = 1:len
        pair_ptr = pairs_ptr + (i - 1) * sizeof(YAMLNodePair)
        pair = unsafe_load(pair_ptr)

        key_node = unsafe_load(yaml_document_get_node(doc_ref, pair.key))
        key = unsafe_string(key_node.data.scalar.value)
        val_ptr = yaml_document_get_node(doc_ref, pair.value)
        val_node = unsafe_load(val_ptr)
        val = parse_node(doc_ref, val_ptr, ctx)

        if key == "<<"
            merge_anchor!(yaml_dict, val, val_node.type)
        else
            yaml_dict[key] = val
        end
    end

    return yaml_dict
end

#__ YAML helpers __#

@inline function merge_anchor!(yaml_dict, val, type)
    if type == YAML_MAPPING_NODE
        merge!(yaml_dict, val)
    elseif type == YAML_SEQUENCE_NODE
        for submap in val
            merge!(yaml_dict, submap)
        end
    else
        throw(YAMLError("Cannot merge the following node type as an anchor: $type"))
    end

    return nothing
end

@inline c_array_length(start, top, size) = (top - start) ÷ size

#__ YAML interface __#

"""
    parse_yaml(yaml_str::String; multi::Bool)
    parse_yaml(yaml_str::Vector{UInt8}; multi::Bool)

Parse a YAML string or file (or vector of `UInt8`) into a dictionary, vector or nothing. 
- If a given YAML document contains a dictionary, the parser returns a dictionary.
- If a given YAML document contains just a list of variables, the parser returns a vector.
- If a given YAML document contains no information (i.e. empty), the parser returns nothing
or empty dictionary.

Returns a sequence of documents parsed from YAML string given.

## Keyword arguments
- `multi::Bool = false`: If YAML is multidocumental, allows the reader to choose between obtaining all documents at once or only the first one.

## Examples
```julia
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
Dict{String, Any}(
    "dict" => Dict{Any, Any}(
        "b" => Any["w", "d"], 
        "a" => "1"
    ), 
    "name" => "Alice", 
    "array" => Any["1", "2", Dict{Any, Any}("b" => nothing, "a" => "3")]
)
```
"""
function parse_yaml(yaml::AbstractString; multi::Bool = false)
    return parse_yaml_str(DefaultContext(), codeunits(yaml), multi = multi)
end

function parse_yaml(yaml::AbstractVector{UInt8}; multi::Bool = false)
    return parse_yaml_str(DefaultContext(), yaml, multi = multi)
end

"""
    open_yaml(path::AbstractString; multi::Bool)

Read a YAML file from a given `path` and parse it.

## Keyword arguments
- `multi::Bool = false`: If YAML is multidocumental, allows the reader to choose between obtaining all documents at once or only the first one.
"""
function open_yaml(path::AbstractString; multi::Bool = false)
    return parse_yaml_file(path, multi = multi)
end

"""
    open_yaml(io::IO; multi::Bool)

Reads a YAML file from a given `io` and parse it.

## Keyword arguments
- `multi::Bool = false`: If YAML is multidocumental, allows the reader to choose between obtaining all documents at once or only the first one.
"""
function open_yaml(io::IO; multi::Bool = false)
    return parse_yaml_str(DefaultContext(), read(io), multi = multi)
end

end # module YAML
