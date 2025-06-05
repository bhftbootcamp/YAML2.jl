const TIMESTAMP_FORMATS = DateFormat[
    dateformat"yyyy-mm-dd",
    dateformat"yyyy-mm-ddTHH:MM:SS",
    dateformat"yyyy-mm-ddTHH:MM:SS.sss",
]

const NAN_KEY_WORDS = Set([".nan", ".NaN", ".NAN"])
const POSITIVE_INF_KEY_WORDS = Set([".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF"])
const NEGATIVE_INF_KEY_WORDS = Set(["-.inf", "-.Inf", "-.INF"])

const BOOL_TRUE_KEY_WORDS = 
    Set(["true", "True", "TRUE", "yes", "Yes", "YES", "on", "On", "ON", "y", "Y"])
const BOOL_FALSE_KEY_WORDS =
    Set(["false", "False", "FALSE", "no", "No", "NO", "off", "Off", "OFF", "n", "N"])

const NULL_KEY_WORDS = Set(["", "~", "null", "Null", "NULL"])

@inline function parse_int(value)
    value = replace(value, "_" => "")
    return parse(Int, value)
end

@inline function parse_float(value)
    value = replace(value, "_" => "")

    if value in NAN_KEY_WORDS
        return NaN
    elseif value in POSITIVE_INF_KEY_WORDS
        return Inf
    elseif value in NEGATIVE_INF_KEY_WORDS
        return -Inf
    end

    return parse(Float64, value)
end

@inline function parse_bool(value)
    if value in BOOL_TRUE_KEY_WORDS
        return true
    elseif value in BOOL_FALSE_KEY_WORDS
        return false
    end

    throw(YAMLError("Invalid boolean literal: $value"))
end

@inline function parse_null(value)
    if value in NULL_KEY_WORDS
        return nothing
    end

    throw(YAMLError("Invalid null specification: $value"))
end

@inline function parse_timestamp(value)
    for fmt in TIMESTAMP_FORMATS
        dt = tryparse(DateTime, value, fmt)
        !isnothing(dt) && return dt
    end

    throw(YAMLError("Unrecognized timestamp format: $value"))
end
