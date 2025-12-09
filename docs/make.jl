using Documenter
using REM

DocMeta.setdocmeta!(REM, :DocTestSetup, :(using REM); recursive=true)

makedocs(
    sitename = "REM.jl",
    modules = [REM],
    authors = "Simone Santoni",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://simoneSantoni.github.io/REM.jl",
        assets = ["assets/rem-icon.svg"],
        edit_link = "main",
    ),
    repo = "https://github.com/simoneSantoni/REM.jl/blob/{commit}{path}#{line}",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Events and Data" => "guide/events.md",
            "Statistics" => "guide/statistics.md",
            "Model Estimation" => "guide/estimation.md",
            "Temporal Decay" => "guide/decay.md",
        ],
        "API Reference" => [
            "Types" => "api/types.md",
            "Statistics" => "api/statistics.md",
            "Estimation" => "api/estimation.md",
        ],
    ],
    warnonly = [:missing_docs],
)

deploydocs(
    repo = "github.com/simoneSantoni/REM.jl.git",
    devbranch = "main",
    versions = [
        "stable" => "dev", # serve dev docs at /stable until a release is tagged
        "dev" => "dev",
    ],
    push_preview = true,
)
