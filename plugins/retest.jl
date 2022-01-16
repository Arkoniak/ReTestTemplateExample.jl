module ReTestTemplate

using Pkg
using TOML
using PkgTemplates
using PkgTemplates: @with_kw_noshow
using PkgTemplates: gen_file, with_project, combined_view, tags, render_file, @plugin, Plugin, DEFAULT_PRIORITY
import PkgTemplates: hook, view, validate, priority

export ReTests

const RETEST_UUID = "e0db7c4e-2690-44b9-bad6-7687da720f89"
const RETEST_DEP = Pkg.PackageSpec(; name="ReTest", uuid=RETEST_UUID)

"""
    ReTests(; project=false)

Sets up testing for packages.

## Keyword Arguments
- `srcdir::String`: dir where template files are located.
- `project::Bool`: Whether or not to create a new project for tests (`test/Project.toml`).
  See [here](https://julialang.github.io/Pkg.jl/v1/creating-packages/#Test-specific-dependencies-in-Julia-1.2-and-above-1)
  for more details.

!!! note
    Managing test dependencies with `test/Project.toml` is only supported
    in Julia 1.2 and later.
"""
@plugin struct ReTests <: Plugin
    srcdir::String = joinpath("plugins", "templates")
    files::Vector{String} = ["runtests.jl", "main.jl", "test01_base.jl"]
    project::Bool = false
end

view(::ReTests, ::Template, pkg::AbstractString) = Dict("PKG" => pkg)
fpath(p, fname) = joinpath(p.srcdir, fname)
priority(::ReTests, ::typeof(hook)) = DEFAULT_PRIORITY - 1

function _validate(p, fname)
    isfile(fpath(p, fname)) || throw(ArgumentError("ReTests: Template file $fname does not exist"))
end

function validate(p::ReTests, t::Template)
    foreach(fname -> _validate(p, fname), p.files)
    p.project && t.julia < v"1.2" && @warn string(
        "Tests: The project option is set to create a project (supported in Julia 1.2 and later) ",
        "but a Julia version older than 1.2 ($(t.julia)) is supported by the template",
    )
end

function render_plugin(p::ReTests, t::Template, fname, pkg::AbstractString)
    return render_file(fpath(p, fname), combined_view(p, t, pkg), tags(p))
end

function _hook(p, t, fname, pkg_dir)
    pkg = basename(pkg_dir)
    path = joinpath(pkg_dir, "test", fname)
    text = render_plugin(p, t, fname, pkg)
    gen_file(path, text)
end

function hook(p::ReTests, t::Template, pkg_dir::AbstractString)
    foreach(fname -> _hook(p, t, fname, pkg_dir), p.files)

    # Then set up the test depdendency in the chosen way.
    f = p.project ? make_test_project : add_test_dependency
    f(pkg_dir)
end

# Create a new test project.
function make_test_project(pkg_dir::AbstractString)
    with_project(() -> Pkg.add(RETEST_DEP), joinpath(pkg_dir, "test"))
end

# Add Test as a test-only dependency.
function add_test_dependency(pkg_dir::AbstractString)
    # Add the dependency manually since there's no programmatic way to add to [extras].
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    get!(toml, "extras", Dict())["ReTest"] = RETEST_UUID
    get!(toml, "targets", Dict())["test"] = ["ReTest"]
    open(io -> TOML.print(io, toml), path, "w")

    # Generate the manifest by updating the project.
    # This also ensures that keys in Project.toml are sorted properly.
    touch(joinpath(pkg_dir, "Manifest.toml"))  # File must exist to be modified by Pkg.
    with_project(Pkg.update, pkg_dir)
end

end # module

using .ReTestTemplate
