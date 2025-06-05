using Test
using LibYAML
using Dates
using OrderedCollections

import LibYAML.ParserYAML:
    parse_yaml,
    open_yaml,
    emit_yaml,
    parse_int,
    parse_float,
    parse_bool,
    isnull_value,
    parse_null,
    parse_timestamp

@testset "1. Scalar Values" begin
    # 1.1: Simple key:value pair
    yaml = """
    key: value
    """
    parsed = parse_yaml(yaml)
    @test parsed["key"] == "value"

    # 1.2: Unquoted number without explicit tag -> parsed as string
    yaml = """
    num: 12345
    """
    parsed = parse_yaml(yaml)
    @test parsed["num"] == "12345"

    # 1.3: Boolean values without explicit tag
    yaml = """
    flag_true: true
    flag_false: false
    """
    parsed = parse_yaml(yaml)
    @test parsed["flag_true"] == "true"
    @test parsed["flag_false"] == "false"

    # 1.4: Quoted strings, single and literal block
    yaml = """
    single: 'It''s YAML'
    double: |-
        Line Break
    """
    parsed = parse_yaml(yaml)
    @test parsed["single"] == "It's YAML"
    @test parsed["double"] == "Line Break"

    # 1.5: Empty value (key without value) -> parsed as nothing
    yaml = """
    empty:
    """
    parsed = parse_yaml(yaml)
    @test isnothing(parsed["empty"])
end

@testset "2. Explicit Tags: Int, Float, Bool, Null, Timestamp" begin
    yaml = """
    int_val: !!int 42
    float_val: !!float 3.1415
    nan_val: !!float .nan
    inf_val: !!float .Inf
    neg_inf: !!float -.INF
    bool_yes: !!bool YES
    bool_no: !!bool no
    null1: !!null null
    null2: !!null ~
    ts_date: !!timestamp 2021-01-01
    ts_datetime: !!timestamp 2021-01-01T12:00:00
    """
    parsed = parse_yaml(yaml)

    @test parsed["int_val"] == 42
    @test parsed["float_val"] ≈ 3.1415
    @test isnan(parsed["nan_val"])
    @test isinf(parsed["inf_val"])
    @test parsed["inf_val"] > 0
    @test parsed["neg_inf"] == -Inf

    @test parsed["bool_yes"] === true
    @test parsed["bool_no"] === false

    @test isnothing(parsed["null1"])
    @test isnothing(parsed["null2"])

    @test parsed["ts_date"] == DateTime(2021, 1, 1)
    @test parsed["ts_datetime"] == DateTime(2021, 1, 1, 12, 0, 0)

    # Invalid explicit tag values should throw
    @test_throws YAMLError parse_yaml("a: !!null abc")
    @test_throws YAMLError parse_yaml("b: !!bool maybe")
    @test_throws YAMLError parse_yaml("c: !!timestamp 2021-13-01")
end

@testset "3. Lists and Dicts" begin
    # 3.1: Simple list of strings and numbers
    yaml = """
    items:
      - one
      - 2
      - true
    """
    parsed = parse_yaml(yaml)
    @test parsed["items"] == ["one", "2", "true"]

    # 3.2: Flow style sequence
    yaml = """
    seq: [1, 2, three]
    """
    parsed = parse_yaml(yaml)
    @test parsed["seq"] == ["1", "2", "three"]

    # 3.3: Nested dictionary
    yaml = """
    settings:
      mode: production
      retries: 3
    """
    parsed = parse_yaml(yaml)
    @test parsed["settings"]["mode"] == "production"
    @test parsed["settings"]["retries"] == "3"

    # 3.4: Flow style mapping
    yaml = """
    map: {a: 1, b: two}
    """
    parsed = parse_yaml(yaml)
    @test parsed["map"] == Dict("a" => "1", "b" => "two")

    # 3.5: Sequence of mixed explicit tags
    yaml = """
    mixed:
      - !!int 10
      - !!float 2.5
      - !!bool false
      - !!null null
    """
    parsed = parse_yaml(yaml)
    @test parsed["mixed"][1] == 10
    @test parsed["mixed"][2] ≈ 2.5
    @test parsed["mixed"][3] === false
    @test isnothing(parsed["mixed"][4])
end

@testset "4. Multiline Strings" begin
    # 4.1: Literal block style (|)
    yaml = """
    literal: |
      line1
      line2
    """
    parsed = parse_yaml(yaml)
    @test parsed["literal"] == "line1\nline2\n"

    # 4.2: Folded block style (>), where newlines collapse into spaces
    yaml = """
    folded: >
      line1
      line2
    """
    parsed = parse_yaml(yaml)
    @test parsed["folded"] == "line1 line2\n"

    # 4.3: Blank lines in folded block
    yaml = """
    example: >
      first line

      third line
    """
    parsed = parse_yaml(yaml)
    @test parsed["example"] == "first line\nthird line\n"
end

@testset "5. Unicode and Emoji Support" begin
    yaml = """
    emoji: 😀
    unicode: Привет
    """
    parsed = parse_yaml(yaml)
    @test parsed["emoji"] == "😀"
    @test parsed["unicode"] == "Привет"
end

@testset "6. Empty and Null Structures" begin
    @test parse_yaml("empty_list: []") == Dict("empty_list" => [])
    @test parse_yaml("empty_dict: {}") == Dict("empty_dict" => Dict())
    @test isnothing(parse_yaml(""))
    @test isnothing(parse_yaml("---"))
    @test parse_yaml("---\n---", multi=true) == Any[nothing, nothing]
end

@testset "7. Multiple Documents" begin
    yaml = """
    ---
    a: 1
    ---
    b: 2
    ...
    ---
    c: 3
    """
    parsed = parse_yaml(yaml, multi = true)
    @test length(parsed) == 3
    @test parsed[1] == Dict("a" => "1")
    @test parsed[2] == Dict("b" => "2")
    @test parsed[3] == Dict("c" => "3")
end

@testset "8. Merge Keys Case" begin
    # 8.1: Merge using single anchor
    yaml = """
    base: &base
      x: 1
      y: 2
    merged:
      <<: *base
      z: 3
    """
    parsed = parse_yaml(yaml)
    @test parsed["merged"] == Dict("x" => "1", "y" => "2", "z" => "3")

    # 8.2: Merge using multiple anchors
    yaml = """
    default: &default
      a: A
    override: &override
      b: B
    combined:
      <<: [*default, *override]
      c: C
    """
    parsed = parse_yaml(yaml)
    @test parsed["combined"] == Dict("a" => "A", "b" => "B", "c" => "C")

    # 8.3: Nested merge
    yaml = """
    defaults: &defaults
      val: 1
    inner: &inner
      <<: *defaults
      inner_val: 2
    outer:
      <<: *inner
      outer_val: 3
    """
    parsed = parse_yaml(yaml)
    @test parsed["outer"] == Dict("val" => "1", "inner_val" => "2", "outer_val" => "3")
end

@testset "9. Include Directive (!include)" begin
    mktempdir() do dir
        base_file = joinpath(dir, "base.yaml")
        write(base_file, "name: test\nversion: 1.0")

        ext_file = joinpath(dir, "ext.yaml")
        write(ext_file, "enabled: true\nthreshold: 5")

        yaml = """
        app:
          !include $(base_file)
        ext:
          !include $(ext_file)
        """
        main_file = joinpath(dir, "main_file.yaml")
        write(main_file, yaml)

        parsed = open_yaml(main_file)
        @test parsed["app"]["name"] == "test"
        @test parsed["app"]["version"] == "1.0"
        @test parsed["ext"]["enabled"] == "true"
        @test parsed["ext"]["threshold"] == "5"
    end

    fake_path = "/nonexistent/path.yaml"
    yaml_bad = """
    data: !include $(fake_path)
    """
    @test_throws YAMLError open_yaml(fake_path)
end

@testset "10. parse_* Functions" begin
    # parse_int
    @test parse_int("123") == 123
    @test parse_int("-42_000") == -42000
    @test_throws YAMLError parse_int("12a3")
    @test_throws YAMLError parse_int("+")
    @test_throws YAMLError parse_int("120_")
    @test_throws YAMLError parse_int("-9223372036854775809")

    # parse_float
    @test parse_float("1_234.56") ≈ 1234.56
    @test isnan(parse_float(".NaN"))
    @test parse_float("-Inf") == -Inf
    @test parse_float("+1.0e2") == 100.0
    @test_throws ArgumentError parse_float("abc")

    # parse_bool
    @test parse_bool("true") === true
    @test parse_bool("No") === false
    @test_throws YAMLError parse_bool("maybe")

    # parse_null
    @test parse_null("") === nothing
    @test parse_null("Null") === nothing
    @test_throws YAMLError parse_null("nil")

    # parse_timestamp
    @test parse_timestamp("2025-01-01") == DateTime(2025, 1, 1)
    @test parse_timestamp("2025-01-01T12:34:56") == DateTime(2025, 1, 1, 12, 34, 56)
    @test_throws YAMLError parse_timestamp("01-01-2025")

    # parse_value within flow
    yaml = """
    data: [!!int 5, !!float 2.2, !!bool true, !!null null]
    """
    parsed = parse_yaml(yaml)
    @test parsed["data"][1] == 5
    @test parsed["data"][2] ≈ 2.2
    @test parsed["data"][3] === true
    @test isnothing(parsed["data"][4])
end

@testset "11. Error Handling and Edge Cases" begin
    @test_throws YAMLScannerError parse_yaml("key: \"noend)")

    # Parser error: wrong indentation
    bad_yaml = """
    a:
      - item1
    - item2
    """
    @test_throws YAMLParserError parse_yaml(bad_yaml)

    # Reader error: invalid bytes
    @test_throws YAMLReaderError parse_yaml("\xff")

    # Invalid merge sequence: merge non-mapping
    # yaml_bad = """
    # seq: &anchor [1,2,3]
    # merged:
    #   <<: *anchor
    #   extra: val
    # """
    # @test_throws YAMLError parse_yaml(yaml_bad)

    # Duplicate keys in same mapping: last one should win
    yaml_dup = """
    dup:
      key: first
      key: second
    """
    parsed = parse_yaml(yaml_dup)
    @test parsed["dup"]["key"] == "second"

    # Comments should be ignored
    yaml = """
    # this is a comment
    a: 1  # inline comment
    b: 2
    """
    parsed = parse_yaml(yaml)
    @test parsed["a"] == "1"
    @test parsed["b"] == "2"

    # Escape sequences in double-quoted strings
    yaml = """
    esc: "Line\\tTabbed"
    unicode_esc: "\\u263A"
    """
    parsed = parse_yaml(yaml)
    @test parsed["esc"] == "Line\tTabbed"
    @test parsed["unicode_esc"] == "☺"
end

@testset "12. Flow vs Block Style" begin
    # Block style mapping
    yaml_block = """
    person:
      name: Alice
      age: 30
    """
    parsed_block = parse_yaml(yaml_block)
    # Flow style mapping
    yaml_flow = """
    person: {name: Alice, age: 30}
    """
    parsed_flow = parse_yaml(yaml_flow)
    @test parsed_block == parsed_flow

    # Block style sequence
    yaml_block_seq = """
    nums:
      - 1
      - 2
      - 3
    """
    parsed_block_seq = parse_yaml(yaml_block_seq)
    # Flow style sequence
    yaml_flow_seq = """
    nums: [1, 2, 3]
    """
    parsed_flow_seq = parse_yaml(yaml_flow_seq)
    @test parsed_block_seq == parsed_flow_seq
end

#@testset "13. Roundtrip Emit-Parse" begin
#    yaml_original = """
#    items:
#      - name: test
#        value: !!int 5
#      - name: demo
#        enabled: !!bool true
#    """
#    parsed = parse_yaml(yaml_original)
#    emitted = to_yaml(parsed)
#    reparsed = parse_yaml(emitted)
#    @test reparsed == parsed
#end

@testset "14. Complex Key Types" begin
    yaml = """
    ? [complex, key]
    : value1
    ? {a: 1, b: 2}
    : value2
    """
    parsed = parse_yaml(yaml)
    @test parsed[["complex", "key"]] == "value1"
    @test parsed[Dict("a" => "1", "b" => "2")] == "value2"
end

@testset "15. Different DictType's" begin
    yaml = """
    default: &default
      a: A
    override: &override
      b: B
    combined:
      <<: [*default, *override]
      c: C
    """

    parsed1 = parse_yaml(yaml; dict_type = IdDict)
    @test parsed1["combined"] == IdDict("a" => "A", "b" => "B", "c" => "C")
    @test typeof(parsed1) <: IdDict

    parsed2 = parse_yaml(yaml; dict_type = OrderedDict)
    @test parsed2["combined"] == OrderedDict("a" => "A", "b" => "B", "c" => "C")
    @test typeof(parsed2) <: OrderedDict
end
