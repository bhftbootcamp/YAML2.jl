module LibYAMLc

using LibYAML_jll

export LIBYAML_NULL_TAG,
    LIBYAML_BOOL_TAG,
    LIBYAML_INT_TAG,
    LIBYAML_FLOAT_TAG,
    LIBYAML_TIMESTAMP_TAG,
    LIBYAML_STR_TAG,
    LIBYAML_SEQ_TAG,
    LIBYAML_MAP_TAG,
    LIBYAML_DEFAULT_SCALAR_TAG

export LibYAMLEncoding,
    LIBYAML_ANY_ENCODING,
    LIBYAML_UTF8_ENCODING,
    LIBYAML_UTF16LE_ENCODING,
    LIBYAML_UTF16BE_ENCODING

export LibYAMLErrorType,
    LIBYAML_NO_ERROR,
    LIBYAML_MEMORY_ERROR,
    LIBYAML_READER_ERROR,
    LIBYAML_SCANNER_ERROR,
    LIBYAML_PARSER_ERROR,
    LIBYAML_COMPOSER_ERROR,
    LIBYAML_WRITER_ERROR,
    LIBYAML_EMITTER_ERROR

export LibYAMLScalarStyle,
    LIBYAML_ANY_SCALAR_STYLE,
    LIBYAML_PLAIN_SCALAR_STYLE,
    LIBYAML_SINGLE_QUOTED_SCALAR_STYLE,
    LIBYAML_DOUBLE_QUOTED_SCALAR_STYLE,
    LIBYAML_LITERAL_SCALAR_STYLE,
    LIBYAML_FOLDED_SCALAR_STYLE

export LibYAMLSequenceStyle,
    LIBYAML_ANY_SEQUENCE_STYLE,
    LIBYAML_BLOCK_SEQUENCE_STYLE,
    LIBYAML_FLOW_SEQUENCE_STYLE

export LibYAMLMappingStyle,
    LIBYAML_ANY_MAPPING_STYLE,
    LIBYAML_BLOCK_MAPPING_STYLE,
    LIBYAML_FLOW_MAPPING_STYLE

export LibYAMLNodeType,
    LIBYAML_NO_NODE,
    LIBYAML_SCALAR_NODE,
    LIBYAML_SEQUENCE_NODE,
    LIBYAML_MAPPING_NODE

export LibYAMLMark,
    LibYAMLNodePair,
    LibYAMLScalarData,
    LibYAMLSequenceStack,
    LibYAMLSequenceData,
    LibYAMLMappingStack,
    LibYAMLMappingData,
    LibYAMLNodeData,
    LibYAMLNode,
    LibYAMLDocument,
    LibYAMLParser

export libyaml_document_delete,
    libyaml_document_get_node,
    libyaml_document_get_root_node,
    libyaml_parser_initialize,
    libyaml_parser_delete,
    libyaml_parser_set_input_string,
    libyaml_parser_set_input_file,
    libyaml_parser_set_input,
    libyaml_parser_set_encoding,
    libyaml_parser_load

const LIBYAML_NULL_TAG = "tag:yaml.org,2002:null"
const LIBYAML_BOOL_TAG = "tag:yaml.org,2002:bool"
const LIBYAML_INT_TAG = "tag:yaml.org,2002:int"
const LIBYAML_FLOAT_TAG = "tag:yaml.org,2002:float"
const LIBYAML_TIMESTAMP_TAG = "tag:yaml.org,2002:timestamp"
const LIBYAML_STR_TAG = "tag:yaml.org,2002:str"
const LIBYAML_SEQ_TAG = "tag:yaml.org,2002:seq"
const LIBYAML_MAP_TAG = "tag:yaml.org,2002:map"
const LIBYAML_DEFAULT_SCALAR_TAG = LIBYAML_STR_TAG

const LibYAMLEncoding = UInt32
const LIBYAML_ANY_ENCODING = 0
const LIBYAML_UTF8_ENCODING = 1
const LIBYAML_UTF16LE_ENCODING = 2
const LIBYAML_UTF16BE_ENCODING = 3

const LibYAMLErrorType = UInt32
const LIBYAML_NO_ERROR = 0
const LIBYAML_MEMORY_ERROR = 1
const LIBYAML_READER_ERROR = 2
const LIBYAML_SCANNER_ERROR = 3
const LIBYAML_PARSER_ERROR = 4
const LIBYAML_COMPOSER_ERROR = 5
const LIBYAML_WRITER_ERROR = 6
const LIBYAML_EMITTER_ERROR = 7

const LibYAMLScalarStyle = UInt32
const LIBYAML_ANY_SCALAR_STYLE = 0
const LIBYAML_PLAIN_SCALAR_STYLE = 1
const LIBYAML_SINGLE_QUOTED_SCALAR_STYLE = 2
const LIBYAML_DOUBLE_QUOTED_SCALAR_STYLE = 3
const LIBYAML_LITERAL_SCALAR_STYLE = 4
const LIBYAML_FOLDED_SCALAR_STYLE = 5

const LibYAMLSequenceStyle = UInt32
const LIBYAML_ANY_SEQUENCE_STYLE = 0
const LIBYAML_BLOCK_SEQUENCE_STYLE = 1
const LIBYAML_FLOW_SEQUENCE_STYLE = 2

const LibYAMLMappingStyle = UInt32
const LIBYAML_ANY_MAPPING_STYLE = 0
const LIBYAML_BLOCK_MAPPING_STYLE = 1
const LIBYAML_FLOW_MAPPING_STYLE = 2

const LibYAMLNodeType = UInt32
const LIBYAML_NO_NODE = 0
const LIBYAML_SCALAR_NODE = 1
const LIBYAML_SEQUENCE_NODE = 2
const LIBYAML_MAPPING_NODE = 3

struct LibYAMLMark
    index::Csize_t
    line::Csize_t
    column::Csize_t
end

struct LibYAMLNodePair
    key::Cint
    value::Cint
end

struct LibYAMLScalarData
    value::Ptr{Cuchar}
    length::Csize_t
    style::LibYAMLScalarStyle
end

struct LibYAMLSequenceStack
    start::Ptr{Cint}
    _end::Ptr{Cint}
    top::Ptr{Cint}
end

struct LibYAMLSequenceData
    items::LibYAMLSequenceStack
    style::LibYAMLSequenceStyle
end

struct LibYAMLMappingStack
    start::Ptr{LibYAMLNodePair}
    _end::Ptr{LibYAMLNodePair}
    top::Ptr{LibYAMLNodePair}
end

struct LibYAMLMappingData
    pairs::LibYAMLMappingStack
    style::LibYAMLMappingStyle
end

struct LibYAMLNodeData
    data::NTuple{32,UInt8}
end

struct LibYAMLNode
    type::LibYAMLNodeType
    tag::Ptr{Cuchar}
    data::LibYAMLNodeData
    start_mark::LibYAMLMark
    end_mark::LibYAMLMark
end

struct LibYAMLDocument
    data::NTuple{104,UInt8}
end

struct LibYAMLParser
    error::LibYAMLErrorType
    problem::Cstring
    problem_offset::Csize_t
    problem_value::Cint
    problem_mark::LibYAMLMark
    context::Cstring
    context_mark::LibYAMLMark
    data::NTuple{392,UInt8}
end

function Base.getproperty(x::Ptr{LibYAMLNodeData}, f::Symbol)
    f === :scalar   && return Ptr{LibYAMLScalarData}(x + 0)
    f === :sequence && return Ptr{LibYAMLSequenceData}(x + 0)
    f === :mapping  && return Ptr{LibYAMLMappingData}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::LibYAMLNodeData, f::Symbol)
    r = Ref{LibYAMLNodeData}(x)
    ptr = Base.unsafe_convert(Ptr{LibYAMLNodeData}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function libyaml_document_delete(doc)
    ccall((:yaml_document_delete, libyaml), Cvoid, (Ptr{LibYAMLDocument},), doc)
end

function libyaml_document_get_node(doc, index)
    ccall((:yaml_document_get_node, libyaml), Ptr{LibYAMLNode}, (Ptr{LibYAMLDocument}, Cint), doc, index)
end

function libyaml_document_get_root_node(doc)
    ccall((:yaml_document_get_root_node, libyaml), Ptr{LibYAMLNode}, (Ptr{LibYAMLDocument},), doc)
end

function libyaml_parser_initialize(parser)
    ccall((:yaml_parser_initialize, libyaml), Cint, (Ptr{LibYAMLParser},), parser)
end

function libyaml_parser_delete(parser)
    ccall((:yaml_parser_delete, libyaml), Cvoid, (Ptr{LibYAMLParser},), parser)
end

function libyaml_parser_set_input_string(parser, input, size)
    ccall((:yaml_parser_set_input_string, libyaml), Cvoid, (Ptr{LibYAMLParser}, Ptr{Cuchar}, Csize_t), parser, input, size)
end

function libyaml_parser_set_input_file(parser, file)
    ccall((:yaml_parser_set_input_file, libyaml), Cvoid, (Ptr{LibYAMLParser}, Ptr{Libc.FILE}), parser, file)
end

function libyaml_parser_set_input(parser, handler, data)
    ccall((:yaml_parser_set_input, libyaml), Cvoid, (Ptr{LibYAMLParser}, Ptr{Cvoid}, Ptr{Cvoid}), parser, handler, data)
end

function libyaml_parser_set_encoding(parser, encoding)
    ccall((:yaml_parser_set_encoding, libyaml), Cvoid, (Ptr{LibYAMLParser}, LibYAMLEncoding), parser, encoding)
end

function libyaml_parser_load(parser, doc)
    ccall((:yaml_parser_load, libyaml), Cint, (Ptr{LibYAMLParser}, Ptr{LibYAMLDocument}), parser, doc)
end

end
