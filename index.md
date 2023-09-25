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

```julia
#hideall

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
#hideall

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

\begin{section}{title="Selva 2"}

\begin{showhtml}{}
```julia
#hideall

import JSServe.TailwindDashboard as D
App() do session
    s = D.Slider("Slider: ", 1:3)
    checkbox = D.Checkbox("Chose:", true)
    menu = D.Dropdown("Menu: ", [sin, tan, cos])
    app = map(checkbox.widget.value, s.widget.value, menu.widget.value) do checkboxval, sliderval, menuval
        DOM.div(checkboxval, sliderval, menuval)
    end
    return JSServe.record_states(session, D.FlexRow(
        D.Card(D.FlexCol(checkbox, s, menu)),
        D.Card(app)
    ))
end


```
\end{showhtml}

\end{section}


\begin{section}{title="Selva 3"}

\begin{showhtml}{}
```julia
#hideall

app = App() do session
    colors = ["black", "gray", "silver", "maroon", "red", "olive", "yellow", "green", "lime", "teal", "aqua", "navy", "blue", "purple", "fuchsia"]
    nsamples = D.Slider("nsamples", 1:200, value=100)
    nsamples.widget[] = 100
    sample_step = D.Slider("sample step", 0.01:0.01:1.0, value=0.1)
    sample_step.widget[] = 0.1
    phase = D.Slider("phase", 0.0:0.1:6.0, value=0.0)
    radii = D.Slider("radii", 0.1:0.1:60, value=10.0)
    radii.widget[] = 10
    svg = DOM.div()
    evaljs(session, js"""
        const [width, height] = [900, 300]
        const colors = $(colors)
        const observables = $([nsamples.value, sample_step.value, phase.value, radii.value])
        function update_svg(args) {
            const [nsamples, sample_step, phase, radii] = args;
            const svg = (tag, attr) => {
                const el = document.createElementNS('http://www.w3.org/2000/svg', tag);
                for (const key in attr) {
                    el.setAttributeNS(null, key, attr[key]);
                }
                return el
            }
            const color = (i) => colors[i % colors.length]
            const svg_node = svg('svg', {width: width, height: height});
            for (let i=0; i<nsamples; i++) {
                const cxs_unscaled = (i + 1) * sample_step + phase;
                const cys = Math.sin(cxs_unscaled) * (height / 3.0) + (height / 2.0);
                const cxs = cxs_unscaled * width / (4 * Math.PI);
                const circle = svg('circle', {cx: cxs, cy: cys, r: radii, fill: color(i)});
                svg_node.appendChild(circle);
            }
            $(svg).replaceChildren(svg_node);
        }
        JSServe.onany(observables, update_svg)
        update_svg(observables.map(x=> x.value))
        """)
    return DOM.div(D.FlexRow(D.FlexCol(nsamples, sample_step, phase, radii), svg))
end


```
\end{showhtml}

\end{section}