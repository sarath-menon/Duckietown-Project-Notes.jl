\begin{section}{}
~~~<div id="mdpad"></div></div>
~~~
\end{section}

\begin{section}{title="Components"}

This is an example app to demonstrate how Julia code for DiffEq-type simulations can be compiled for use on the web. This app is built with the following:

* [StaticCompiler](https://github.com/tshort/StaticCompiler.jl) compiles a Julia model to WebAssembly. This uses [GPUCompiler](https://github.com/JuliaGPU/GPUCompiler.jl) which does most of the work. [StaticTools](https://github.com/brenhinkeller/StaticTools.jl) helps with this static compilation.
* [DiffEqGPU](https://github.com/SciML/DiffEqGPU.jl) provides simulation code that is amenable to static compilation.
* [WebAssemblyInterfaces](https://github.com/tshort/WebAssemblyInterfaces.jl) and [wasm-ffi](https://github.com/demille/wasm-ffi) provide convenient ways to interface between JavaScript and Julia/WebAssembly code.
* [mdpad](https://mdpad.netlify.app/) provides features for single-page web apps.
* [PkgPage](https://github.com/tlienart/PkgPage.jl) and [Franklin](https://github.com/tlienart/Franklin.jl) build this page from Markdown. The source code on this page also compiles the WebAssembly modeling code.

\end{section}

\begin{section}{title="WebAssembly"}

Here is the model with initial conditions that we'll compile. The important part is using [DiffEqGPU](https://github.com/SciML/DiffEqGPU.jl) to set up an integrator. Because it is designed to run on a GPU, it is natural for static compilation. It doesn't allocate or use features from `libjulia`.

```julia:j1
using DiffEqGPU, StaticArrays, OrdinaryDiffEq
using StaticTools
using JSServe

# tres = MallocVector{Float64}(undef,)
# u0 = MallocVector{Float64}
# u1 = MallocVector{Float64}
# u2 = MallocVector{Float64}

function lorenz(u, p, t)
    σ = p[1]
    ρ = p[2]
    β = p[3]
    du1 = σ * (u[2] - u[1])
    du2 = u[1] * (ρ - u[3]) - u[2
    du3 = u[1] * u[2] - β * u[3]
    return SVector{3}(du1, du2, du3)
end

u0 = @SVector [1.0; 0.0; 0.0]
tspan = (0.0, 20.0)
p = @SVector [10.0, 28.0, 8 / 3.0]
prob = ODEProblem{false}(lorenz, u0, tspan, p)

integ = DiffEqGPU.init(GPUTsit5(), prob.f, false, u0, 0.0, 0.005, p, nothing, CallbackSet(nothing), true, false)


function first_order_sys!(x, p, t)
    τ = p[1]

    dx = (1. - x[1]) / τ

    return SVector{1}(dx)
end

X0 = @SVector [0.0]
tspan = (0.0, 20.0)
p2 = @SVector [0.2]
prob2 = ODEProblem{false}(first_order_sys!, X0, tspan, p2)

integ2 = DiffEqGPU.init(GPUTsit5(), prob2.f, false, X0, 0.0, 0.005, p2, nothing, CallbackSet(nothing), true, false)
```

\end{section}

\begin{section}{title="Selva"}

\begin{showhtml}{}
```julia
using OrdinaryDiffEq
using WGLMakie
using Markdown

Page(exportable=true, offline=true) # for Franklin, you still need to configure
WGLMakie.activate!()
# Makie.inline!(true) # Make sure to inline plots into Documenter output!

# must be true to be found inside the DOM
is_widget(x) = true
# Updating the widget isn't dependant on any other state (only thing supported right now)
is_independant(x) = true
# The values a widget can iterate
function value_range end
# updating the widget with a certain value (usually an observable)
function update_value!(x, value) end

# forcing function
u(t) = 1

first_order_sys!(t,x;τ,u) = (u(t) - x) / τ

function first_order_sys!(dX, X, params, t)

    # extract the parameters
    τ = params.τ

    # extract the state
    x = X[1]
    
    # x_dot = (u(t) - x) / τ
    x_dot = first_order_sys!(t,x;τ=τ,u=u)

    dX[1] = x_dot
end

App() do session::Session
    n = 20
    index_slider = Slider(0.1:0.1:n)

    X0 =  [0.0]

    tspan = (0.0, 5.0)
    parameters = (;τ=0.2)
    
    prob2 = ODEProblem(first_order_sys!, X0, tspan, parameters)
    sol = solve(prob2, Tsit5(), reltol = 1e-8, abstol = 1e-8)
    
    fig = Figure()
    ax = Axis(fig[1, 1], limits=(0,10000,0,1.5))

    y_vec = Observable{Vector{Float64}}([0.])
    

    integ = DiffEqGPU.init(GPUTsit5(), prob.f, false, u0, 0.0, 0.005, p, nothing, CallbackSet(nothing), true, false)
    tres = MallocVector{Float64}(undef,10000)
    u1 = MallocVector{Float64}(undef,10000)

    t_vec =  collect(Int32(1):Int32(10000))
    lines!(ax, t_vec, y_vec)
    
    on(index_slider) do val  

        X0 = @SVector [0.0]
        p2 = @SVector [Float64(val) / 10.0]
        integ2 = DiffEqGPU.init(GPUTsit5(), prob2.f, false, X0, 0.0, 0.005, p2, nothing, CallbackSet(nothing), true, false)

        for i in Int32(1):Int32(10000)
          @inline DiffEqGPU.step!(integ2, integ2.t + integ2.dt, integ2.u)
          tres[i] = integ2.t
          u1[i] = integ2.u[1]
        end

        y_vec[] = u1
    end
    
    slider = DOM.div("z-index: ", index_slider, index_slider.value)
    return JSServe.record_states(session, DOM.div(slider, fig))
end


```
\end{showhtml}

\end{section}





