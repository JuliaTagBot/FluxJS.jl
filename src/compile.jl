using DataFlow

struct Meth
  func
  args::Tuple
  graph
end

matVecMul(args...) = *(args...)

jsarray_constructor(x) = :(dl.$(Symbol("Array$(ndims(x))D")).new)
jsarray(x::AbstractVector) = vcall(jsarray_constructor(x), Flux.Tracker.data(x))
jsarray(x) = vcall(jsarray_constructor(x), size(x), vec(Flux.Tracker.data(x)))

jscall(args...) = vcall(args...)

jscall(::typeof(identity), x) = x

cvalue(v) = DataFlow.isconstant(v) ? v.value.value : v

function inline_methods(v)
  DataFlow.prewalkλ(v) do v
    cvalue(v) isa Meth ? vcall(identity, cvalue(v).graph) : v
  end
end

function lower(v)
  v = inline_methods(v)
  v = DataFlow.prewalk(v -> DataFlow.islambda(v) ? DataFlow.λopen(v) : v, v)
  v = DataFlow.postwalk(v) do v
    v.value isa DataFlow.Line && return v[1]
    cvalue(v) isa AbstractArray && return jsarray(cvalue(v))
    DataFlow.iscall(v) || return v
    jscall(cvalue.(v[:])...)
  end
  v = DataFlow.postwalk(v -> v.value isa DataFlow.OLambda ? DataFlow.λclose(v) : v, v)
  DataFlow.prewalkλ(v) do v
    DataFlow.iscall(v, control) ? v[2] : v
  end
end

macro code_js(ex)
  @capture(ex, f_(args__)) || error("@code_js f(args...)")
  quote
    Text(compile(traceλ($(esc(f)), $(map(arg -> :(stage($(esc(arg)))), args)...))))
  end
end
