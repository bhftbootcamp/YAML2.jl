using LibYAML
using Documenter

DocMeta.setdocmeta!(LibYAML, :DocTestSetup, :(using LibYAML); recursive = true)

makedocs(;
    modules = [LibYAML],
    sitename = "LibYAML.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/bhftbootcamp/LibYAML.jl",
        canonical = "https://bhftbootcamp.github.io/LibYAML.jl",
        edit_link = "master",
        assets = ["assets/favicon.ico"],
        sidebar_sitename = true,  # Set to 'false' if the package logo already contain its name
    ),
    pages = [
        "Home"    => "index.md",
        "API Reference" => "pages/api_reference.md",
        # Add your pages here ...
    ],
    warnonly = [:doctest, :missing_docs],
)

deploydocs(;
    repo = "github.com/bhftbootcamp/LibYAML.jl",
    devbranch = "master",
    push_preview = true,
)
