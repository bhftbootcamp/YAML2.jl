abstract type AbstractYAMLError <: Exception end

struct Mark
    line::Int64
    column::Int64
end

struct YAMLError <: AbstractYAMLError
    msg::String
end

struct YAMLMemoryError <: AbstractYAMLError
    ctx::String
    ctx_mark::Mark
    problem::String
    prob_mark::Mark
end

struct YAMLReaderError <: AbstractYAMLError
    ctx::String
    ctx_mark::Mark
    problem::String
    prob_mark::Mark
end

struct YAMLScannerError <: AbstractYAMLError
    ctx::String
    ctx_mark::Mark
    problem::String
    prob_mark::Mark
end

struct YAMLParserError <: AbstractYAMLError
    ctx::String
    ctx_mark::Mark
    problem::String
    prob_mark::Mark
end

function Base.showerror(io::IO, err::YAMLError)
    return print(io, nameof(typeof(err)), ": ", err.msg)
end

function Base.showerror(io::IO, err::AbstractYAMLError)
    print(io, nameof(typeof(err)), ": ")
    if hasproperty(err, :ctx) && !isempty(err.ctx)
        print(
            io,
            "in ",
            err.ctx,
            " at line ",
            err.ctx_mark.line,
            ", column ",
            err.ctx_mark.column,
            ": ",
        )
    end
    return print(
        io,
        err.problem,
        " at line ",
        err.prob_mark.line,
        ", column ",
        err.prob_mark.column,
    )
end

function throw_yaml_err(parser::YAMLParser)
    err_type = parser.error
    ctx_ptr = parser.context
    prob_ptr = parser.problem

    ctx_str = ctx_ptr == C_NULL ? "" : unsafe_string(ctx_ptr)
    prob_str = unsafe_string(prob_ptr)

    ctx_mark =
        Mark(Int(parser.context_mark.line), Int(parser.context_mark.column))
    prob_mark =
        Mark(Int(parser.problem_mark.line), Int(parser.problem_mark.column))

    if err_type == YAML_MEMORY_ERROR
        throw(YAMLMemoryError(ctx_str, ctx_mark, prob_str, prob_mark))
    elseif err_type == YAML_READER_ERROR
        throw(YAMLReaderError(ctx_str, ctx_mark, prob_str, prob_mark))
    elseif err_type == YAML_SCANNER_ERROR
        throw(YAMLScannerError(ctx_str, ctx_mark, prob_str, prob_mark))
    elseif err_type == YAML_PARSER_ERROR
        throw(YAMLParserError(ctx_str, ctx_mark, prob_str, prob_mark))
    end

    throw(YAMLError(prob))
end
