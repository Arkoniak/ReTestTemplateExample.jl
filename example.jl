using PkgTemplates

include("plugins/retest.jl")

t = Template(
    user="Arkoniak",
    authors=["Andrey Oskin"],
    julia=v"1",
    dir=".",
    plugins=[
               !Tests,
               Git(; ssh = true, ignore = ["Manifest.toml"]),
               License(; name="MIT"),
               Codecov(),
               GitHubActions(; extra_versions=["1.0", "1", "nightly"]),
               TagBot(),
               CompatHelper(),
               ReTests(),
               Documenter{GitHubActions}(),
               # Develop(),
           ],
)
t("MyExample.jl")
