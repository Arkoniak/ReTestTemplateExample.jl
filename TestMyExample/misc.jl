using Revise
using MyExample
using ReTest

ReTest.load("../MyExample/test/main.jl")

retest("foo")
