module BaseTest

using MyExample
using ReTest

@testset "initial" begin
    @test true
end

@testset "foo" begin
    @test true
end

end # module
