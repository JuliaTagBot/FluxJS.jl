using Flux, FluxJS, DataFlow, MacroTools
using FluxJS: traceλ
using Base.Test
using JSExpr, JSON, WebIO
using Blink

include("./helpers.jl")

@testset "FluxJS" begin

m = Dense(10,5)
v = traceλ(m, rand(10))
ex = prettify(DataFlow.syntax(traceλ(m,rand(10))))

@test @capture ex _ -> (+).(matVecMul(_,_),_)

w = setupWindow()

@testset "Dense Layer" begin
    m = Chain(Dense(10, 10))
    x = rand(10)
    testjs(w, m, x)
end

@testset "broadcast" begin
    x = rand(10)
    b = ones(10)

    m = Chain(x -> x .+ b)
    testjs(w, m, x)

    m = Chain(x -> x .* b)
    testjs(w, m, x)

    m = Chain(x -> x ./ b)
    testjs(w, m, x)

    m = Chain(x -> x .- b)
    testjs(w, m, x)

    m = Chain(x -> exp.(x))
    testjs(w, m, x)

    m = Chain(x -> log.(x))
    testjs(w, m, x)

    m = Chain(x -> x .^ [2])
    testjs(w, m, x)

    m = Chain(x -> σ.(x))
    testjs(w, m, x)

    m = Chain(x -> tanh.(x))
    testjs(w, m, x)

    m = Chain(x -> relu.(x))
    testjs(w, m, x)

    m = Chain(x -> leakyrelu.(x))
    testjs(w, m, x)

    m = Chain(x -> copy.(x))
    testjs(w, m, x)
end

@testset "BatchNorm" begin
    m = Chain(BatchNorm(10))
    Flux.testmode!(m)
    x = rand(10, 1)
    testjs(w, m, x)
end

@testset "reshape" begin
    m = Chain(x -> reshape(x, :, size(x, 3)))
    x = rand(1, 2, 3)
    testjs(w, m, x)
end

@testset "LSTM" begin
    m = Chain(x -> Flux.gate(x, 4, 1))
    x = rand(10)
    testjs(w, m, x)

    m = Chain(LSTM(10, 10))
    x = rand(10)
    testjs(w, m, x)
end

@testset "mean" begin
    m = Chain(x -> mean(x, 1))
    x = rand(10, 10)
    testjs(w, m, x)
end

end
