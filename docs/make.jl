using LibYAML2
using Documenter

DocMeta.setdocmeta!(LibYAML2, :DocTestSetup, :(using LibYAML2); recursive = true)

makedocs(;
    modules = [LibYAML2],
    sitename = "LibYAML2.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/bhftbootcamp/LibYAML2.jl",
        canonical = "https://bhftbootcamp.github.io/LibYAML2.jl",
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
    repo = "github.com/bhftbootcamp/LibYAML2.jl",
    devbranch = "master",
    push_preview = true,
)
