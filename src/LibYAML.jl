module LibYAML

using LibYAML_jll

export YAML_NULL_TAG,
    YAML_BOOL_TAG,
    YAML_INT_TAG,
    YAML_FLOAT_TAG,
    YAML_TIMESTAMP_TAG,
    YAML_STR_TAG,
    YAML_SEQ_TAG,
    YAML_MAP_TAG,
    YAML_DEFAULT_SCALAR_TAG

export YAMLEncoding,
    YAML_ANY_ENCODING, YAML_UTF8_ENCODING, YAML_UTF16LE_ENCODING, YAML_UTF16BE_ENCODING

export YAMLErrorType,
    YAML_NO_ERROR,
    YAML_MEMORY_ERROR,
    YAML_READER_ERROR,
    YAML_SCANNER_ERROR,
    YAML_PARSER_ERROR,
    YAML_COMPOSER_ERROR,
    YAML_WRITER_ERROR,
    YAML_EMITTER_ERROR

export YAMLScalarStyle,
    YAML_ANY_SCALAR_STYLE,
    YAML_PLAIN_SCALAR_STYLE,
    YAML_SINGLE_QUOTED_SCALAR_STYLE,
    YAML_DOUBLE_QUOTED_SCALAR_STYLE,
    YAML_LITERAL_SCALAR_STYLE,
    YAML_FOLDED_SCALAR_STYLE

export YAMLSequenceStyle,
    YAML_ANY_SEQUENCE_STYLE, YAML_BLOCK_SEQUENCE_STYLE, YAML_FLOW_SEQUENCE_STYLE

export YAMLMappingStyle,
    YAML_ANY_MAPPING_STYLE, YAML_BLOCK_MAPPING_STYLE, YAML_FLOW_MAPPING_STYLE

export YAMLNodeType, YAML_NO_NODE, YAML_SCALAR_NODE, YAML_SEQUENCE_NODE, YAML_MAPPING_NODE

export YAMLMark,
    YAMLNodeData,
    YAMLNode,
    YAMLNodePair,
    YAMLDocument,
    YAMLParser,
    YAMLScalarData,
    YAMLMappingData,
    YAMLMappingStack,
    YAMLSequenceData,
    YAMLSequenceStack

export yaml_document_delete,
    yaml_document_get_node,
    yaml_document_get_root_node,
    yaml_parser_initialize,
    yaml_parser_delete,
    yaml_parser_set_input_string,
    yaml_parser_set_input_file,
    yaml_parser_set_input,
    yaml_parser_set_encoding,
    yaml_parser_load

export parse_yaml,
    open_yaml,
    YAMLError,
    YAMLMemoryError,
    YAMLReaderError,
    YAMLScannerError,
    YAMLParserError,
    EmptyResolver,
    Resolver

const YAML_NULL_TAG = "tag:yaml.org,2002:null"
const YAML_BOOL_TAG = "tag:yaml.org,2002:bool"
const YAML_STR_TAG = "tag:yaml.org,2002:str"
const YAML_INT_TAG = "tag:yaml.org,2002:int"
const YAML_FLOAT_TAG = "tag:yaml.org,2002:float"
const YAML_TIMESTAMP_TAG = "tag:yaml.org,2002:timestamp"
const YAML_SEQ_TAG = "tag:yaml.org,2002:seq"
const YAML_MAP_TAG = "tag:yaml.org,2002:map"
const YAML_DEFAULT_SCALAR_TAG = YAML_STR_TAG

const YAMLEncoding = UInt32
const YAML_ANY_ENCODING = 0
const YAML_UTF8_ENCODING = 1
const YAML_UTF16LE_ENCODING = 2
const YAML_UTF16BE_ENCODING = 3

const YAMLErrorType = UInt32
const YAML_NO_ERROR = 0
const YAML_MEMORY_ERROR = 1
const YAML_READER_ERROR = 2
const YAML_SCANNER_ERROR = 3
const YAML_PARSER_ERROR = 4
const YAML_COMPOSER_ERROR = 5
const YAML_WRITER_ERROR = 6
const YAML_EMITTER_ERROR = 7

const YAMLScalarStyle = UInt32
const YAML_ANY_SCALAR_STYLE = 0
const YAML_PLAIN_SCALAR_STYLE = 1
const YAML_SINGLE_QUOTED_SCALAR_STYLE = 2
const YAML_DOUBLE_QUOTED_SCALAR_STYLE = 3
const YAML_LITERAL_SCALAR_STYLE = 4
const YAML_FOLDED_SCALAR_STYLE = 5

const YAMLSequenceStyle = UInt32
const YAML_ANY_SEQUENCE_STYLE = 0
const YAML_BLOCK_SEQUENCE_STYLE = 1
const YAML_FLOW_SEQUENCE_STYLE = 2

const YAMLMappingStyle = UInt32
const YAML_ANY_MAPPING_STYLE = 0
const YAML_BLOCK_MAPPING_STYLE = 1
const YAML_FLOW_MAPPING_STYLE = 2

const YAMLNodeType = UInt32
const YAML_NO_NODE = 0
const YAML_SCALAR_NODE = 1
const YAML_SEQUENCE_NODE = 2
const YAML_MAPPING_NODE = 3

struct YAMLDocument
    data::NTuple{104,UInt8}
end

struct YAMLMark
    index::Csize_t
    line::Csize_t
    column::Csize_t
end

struct YAMLNodePair
    key::Cint
    value::Cint
end

struct YAMLScalarData
    value::Ptr{Cuchar}
    length::Csize_t
    style::YAMLScalarStyle
end

struct YAMLSSequenceStack
    start::Ptr{Cint}
    _end::Ptr{Cint}
    top::Ptr{Cint}
end

struct YAMLSSequenceData
    items::YAMLSSequenceStack
    style::YAMLSequenceStyle
end

struct YAMLMappingStack
    start::Ptr{YAMLNodePair}
    _end::Ptr{YAMLNodePair}
    top::Ptr{YAMLNodePair}
end

struct YAMLMappingData
    pairs::YAMLMappingStack
    style::YAMLMappingStyle
end

struct YAMLNodeData
    data::NTuple{32,UInt8}
end

struct YAMLNode
    type::YAMLNodeType
    tag::Ptr{Cuchar}
    data::YAMLNodeData
    start_mark::YAMLMark
    end_mark::YAMLMark
end

struct YAMLParser
    error::YAMLErrorType
    problem::Cstring
    problem_offset::Csize_t
    problem_value::Cint
    problem_mark::YAMLMark
    context::Cstring
    context_mark::YAMLMark
    data::NTuple{392,UInt8}
end

function Base.getproperty(x::Ptr{YAMLNodeData}, f::Symbol)
    f === :scalar && return Ptr{YAMLScalarData}(x + 0)
    f === :sequence && return Ptr{YAMLSSequenceData}(x + 0)
    f === :mapping && return Ptr{YAMLMappingData}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::YAMLNodeData, f::Symbol)
    r = Ref{YAMLNodeData}(x)
    ptr = Base.unsafe_convert(Ptr{YAMLNodeData}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function yaml_document_delete(document)
    @ccall libyaml.yaml_document_delete(document::Ptr{YAMLDocument})::Cvoid
end

function yaml_document_get_node(document, index)
    @ccall libyaml.yaml_document_get_node(
        document::Ptr{YAMLDocument},
        index::Cint,
    )::Ptr{YAMLNode}
end

function yaml_document_get_root_node(document)
    @ccall libyaml.yaml_document_get_root_node(document::Ptr{YAMLDocument})::Ptr{YAMLNode}
end

function yaml_parser_initialize(parser)
    @ccall libyaml.yaml_parser_initialize(parser::Ptr{YAMLParser})::Cint
end

function yaml_parser_delete(parser)
    @ccall libyaml.yaml_parser_delete(parser::Ptr{YAMLParser})::Cvoid
end

function yaml_parser_set_input_string(parser, input, size)
    @ccall libyaml.yaml_parser_set_input_string(
        parser::Ptr{YAMLParser},
        input::Ptr{Cuchar},
        size::Csize_t,
    )::Cvoid
end

function yaml_parser_set_input_file(parser, file)
    @ccall libyaml.yaml_parser_set_input_file(
        parser::Ptr{YAMLParser},
        file::Ptr{Libc.FILE},
    )::Cvoid
end

function yaml_parser_set_input(parser, handler, data)
    @ccall libyaml.yaml_parser_set_input(
        parser::Ptr{YAMLParser},
        handler::Ptr{Cvoid},
        data::Ptr{Cvoid},
    )::Cvoid
end

function yaml_parser_set_encoding(parser, encoding)
    @ccall libyaml.yaml_parser_set_encoding(
        parser::Ptr{YAMLParser},
        encoding::YAMLEncoding,
    )::Cvoid
end

function yaml_parser_load(parser, document)
    @ccall libyaml.yaml_parser_load(
        parser::Ptr{YAMLParser},
        document::Ptr{YAMLDocument},
    )::Cint
end

include("ParserYAML.jl")
using .ParserYAML

end # module
