#__ yaml_values.jl

using Dates

const TIMESTAMP_FORMATS = (
    dateformat"yyyy-mm-dd",
    dateformat"yyyy-mm-ddTHH:MM:SS",
    dateformat"yyyy-mm-ddTHH:MM:SS.sss",
)

const _FLOAT_BUFFER = Vector{UInt8}(undef, 1024)

@inline function parse_int(value::AbstractString)::Int
    if isempty(value)
        throw(YAMLError("Invalid integer literal: $value"))
    end
    i = firstindex(value)
    j = lastindex(value)
    positive = true
    c = value[i]
    if c == '+'
        i += 1
    elseif c == '-'
        positive = false
        i += 1
    end
    if i > j
        throw(YAMLError("Invalid integer literal: $value"))
    end
    if value[i] == '_' || value[j] == '_'
        throw(YAMLError("Invalid integer literal: $value"))
    end
    x = zero(Int)
    @inbounds while i ≤ j
        c = value[i]
        if c == '_'
            # continue
        elseif '0' <= c <= '9'
            digit = Int(UInt8(c) - UInt8('0'))
            if x > typemax(Int) ÷ 10 || (x == typemax(Int) ÷ 10 && digit > typemax(Int) % 10)
                throw(YAMLError("Integer overflow: $value"))
            end
            x = x * 10 + digit
        else
            throw(YAMLError("Invalid integer literal: $value"))
        end
        i += 1
    end
    return positive ? x : -x
end

@inline function parse_float(value::AbstractString)::Float64
    v = value
    if     v == ".nan"  || v == ".NaN"  || v == ".NAN"
        return NaN
    elseif v == ".inf"  || v == ".Inf"  || v == ".INF" ||
           v == "+.inf" || v == "+.Inf" || v == "+.INF"
        return +Inf
    elseif v == "-.inf" || v == "-.Inf" || v == "-.INF"
        return -Inf
    end
    di = 1
    @inbounds for c in value
        if c != '_'
            _FLOAT_BUFFER[di] = UInt8(c)
            di += 1
        end
    end
    len = di - 1
    return parse(Float64, unsafe_string(pointer(_FLOAT_BUFFER), len))
end

@inline function parse_bool(value::AbstractString)::Bool
    v = value
    if     v == "true"   || v == "True"   || v == "TRUE"    ||
           v == "yes"    || v == "Yes"    || v == "YES"     ||
           v == "on"     || v == "On"     || v == "ON"      ||
           v == "y"      || v == "Y"
        return true
    elseif v == "false"  || v == "False"  || v == "FALSE"   ||
           v == "no"     || v == "No"     || v == "NO"      ||
           v == "off"    || v == "Off"    || v == "OFF"     ||
           v == "n"      || v == "N"
        return false
    end
    throw(YAMLError("Invalid boolean literal: $value"))
end

@inline function isnull_value(value::AbstractString)::Bool
    v = value
    return v == ""     || v == "~"    ||
           v == "null" || v == "Null" || v == "NULL"
end

@inline function parse_null(value::AbstractString)::Nothing
    if isnull_value(value)
        return nothing
    end
    throw(YAMLError("Invalid null literal: $value"))
end

@inline function parse_timestamp(value::AbstractString)::DateTime
    @inbounds for fmt in TIMESTAMP_FORMATS
        dt = tryparse(DateTime, value, fmt)
        if dt !== nothing
            return dt
        end
    end
    throw(YAMLError("Unrecognized timestamp format: $value"))
end
