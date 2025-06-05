# yaml_errors.jl

"""
    AbstractYAMLError <: Exception

Abstract error type for its subtypes.
"""
abstract type AbstractYAMLError <: Exception end

struct YAMLMark
    line::Int
    column::Int
end

YAMLMark(cmark::LibYAMLMark) = YAMLMark(Int(cmark.line), Int(cmark.column))

"""
    YAMLError <: AbstractYAMLError

General YAML error.

## Fields
- `msg::String`: The message of the error.
"""
struct YAMLError <: AbstractYAMLError
    msg::String
end

"""
    YAMLMemoryError <: AbstractYAMLError

Memory allocation error returned when resources cannot be allocated.

## Fields
- `context::String`: The context of the error.
- `context_mark::YAMLMark`: The position (line and column) of the context, where the error occured.
- `problem::String`: The message of the error.
- `problem_mark::YAMLMark`: The position (line and column) of the place, where the error occured.
"""
struct YAMLMemoryError <: AbstractYAMLError
    context::String
    context_mark::YAMLMark
    problem::String
    problem_mark::YAMLMark
end

"""
    YAMLReaderError <: AbstractYAMLError

Error reading of a YAML document.

## Fields
- `context::String`: The context of the error.
- `context_mark::YAMLMark`: The position (line and column) of the context, where the error occured.
- `problem::String`: The message of the error.
- `problem_mark::YAMLMark`: The position (line and column) of the place, where th error occured.
"""
struct YAMLReaderError <: AbstractYAMLError
    context::String
    context_mark::YAMLMark
    problem::String
    problem_mark::YAMLMark
end

"""
    YAMLScannerError <: AbstractYAMLError

Error tokenizing YAML stream.

## Fields
- `context::String`: The context of the error.
- `context_mark::YAMLMark`: The position (line and column) of the context, where the error occured.
- `problem::String`: The message of the error.
- `problem_mark::YAMLMark`: The position (line and column) of the place, where th error occured.
"""
struct YAMLScannerError <: AbstractYAMLError
    context::String
    context_mark::YAMLMark
    problem::String
    problem_mark::YAMLMark
end

"""
    YAMLParserError <: AbstractYAMLError

Error parsing YAML document structure.

## Fields
- `context::String`: The context of the error.
- `context_mark::YAMLMark`: The position (line and column) of the context, where the error occured.
- `problem::String`: The message of the error.
- `problem_mark::YAMLMark`: The position (line and column) of the place, where th error occured.
"""
struct YAMLParserError <: AbstractYAMLError
    context::String
    context_mark::YAMLMark
    problem::String
    problem_mark::YAMLMark
end

function Base.showerror(io::IO, e::YAMLError)
    print(io, nameof(typeof(e)), ": ", e.msg)
end

function Base.showerror(io::IO, e::AbstractYAMLError)
    print(io, nameof(typeof(e)), ": ")
    if hasproperty(e, :context) && !isempty(e.context)
        print(io,
          "in ", e.context,
          " at line ", e.context_mark.line,
          ", column ", e.context_mark.column, ": ")
    end
    print(io,
      e.problem,
      " at line ", e.problem_mark.line,
      ", column ", e.problem_mark.column)
end

function throw_yaml_err(parser::LibYAMLParser)
    context = parser.context == C_NULL ? "" : unsafe_string(parser.context)
    problem = unsafe_string(parser.problem)
    context_mark = YAMLMark(parser.context_mark)
    problem_mark = YAMLMark(parser.problem_mark)

    if parser.error == LIBYAML_MEMORY_ERROR
        throw(YAMLMemoryError(context, context_mark, problem, problem_mark))
    elseif parser.error == LIBYAML_READER_ERROR
        throw(YAMLReaderError(context, context_mark, problem, problem_mark))
    elseif parser.error == LIBYAML_SCANNER_ERROR
        throw(YAMLScannerError(context, context_mark, problem, problem_mark))
    elseif parser.error == LIBYAML_PARSER_ERROR
        throw(YAMLParserError(context, context_mark, problem, problem_mark))
    else
        throw(YAMLError(problem))
    end
end
