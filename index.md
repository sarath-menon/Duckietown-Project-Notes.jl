
\begin{section}{title="Components"}

This is an example app to demonstrate how Julia code for DiffEq-type simulations can be compiled for use on the web. This app is built with the following:

* [StaticCompiler](https://github.com/tshort/StaticCompiler.jl) compiles a Julia model to WebAssembly. This uses [GPUCompiler](https://github.com/JuliaGPU/GPUCompiler.jl) which does most of the work. [StaticTools](https://github.com/brenhinkeller/StaticTools.jl) helps with this static compilation.


\end{section}

\begin{section}{title="WebAssembly"}

Here is the model with initial conditions that we'll compile. The important part is using [DiffEqGPU](https://github.com/SciML/DiffEqGPU.jl) to set up an integrator. Because it is designed to run on a GPU, it is natural for static compilation. It doesn't allocate or use features from `libjulia`.

\end{section}

<!-- \begin{section}{title="Selva"}

\begin{showhtml}{}
```julia
#hideall
using StaticArrays
using DiffEqGPU, OrdinaryDiffEq
using WGLMakie
using Markdown
using JSServe
using StaticTools
import JSServe.TailwindDashboard as D

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

function first_order_sys!(X, params, t)
#function first_order_sys!(dX, X, params, t)

    # extract the parameters
    τ = params.τ

    # extract the state
    x = X[1]
    
    # x_dot = (u(t) - x) / τ
    x_dot = first_order_sys!(t,x;τ=τ,u=u)

    # dX[1] = x_dot
    # return nothing
    return SVector{1}([x_dot])
end

App() do session
    s = D.Slider("Time constant: ", 0.1:0.1:10.)

    # variables
    t = MallocVector{Float64}(undef,1000)
    y1 = MallocVector{Float64}(undef,1000)

    # diffeq solver
    # X0 = @SVector [0.0]
    X0 = SVector{1}([0.0])
    tspan = (0.0, 5.0)
    parameters = (;τ=0.2)
    
    prob2 = ODEProblem(first_order_sys!, X0, tspan, parameters)

    # plotting
    fig = Figure(resolution=(800,600))
    ax = Axis(fig[1, 1], 
        limits=(tspan[1], tspan[2], 0, 1.),
        title="First order response",
        titlefont=:regular,
        titlesize=30,
        xlabelsize=25,
        ylabelsize=25,
        xticklabelsize=25,
        yticklabelsize=25)

    x_vec = Observable{Vector{Float64}}([0.])
    y_vec = Observable{Vector{Float64}}([0.])

    lines!(ax, x_vec, y_vec)

    # interactions
    app = map(s.widget.value) do val
        p2 = (;τ=Float64(val) / 10.0)
        
        integ2 = DiffEqGPU.init(GPUTsit5(), prob2.f, false, X0, 0.0, 0.005, p2, nothing, CallbackSet(nothing), true, false)

        for i in Int32(1):Int32(1000)
            t[i] = integ2.t
            y1[i] = integ2.u[1]
            
          @inline DiffEqGPU.step!(integ2, integ2.t + integ2.dt, integ2.u)
          
        end
        
        x_vec[] =  t
        y_vec[] =  y1
    end
    
    widget_box = D.FlexRow(D.Card(D.FlexCol(s)), D.Card(fig))
    
    return JSServe.record_states(session,  DOM.div(widget_box))
end


```
\end{showhtml}
\end{section} -->

\begin{section}{title="WebAssembly"}

```julia:selv
#hideall

using StaticArrays
using DiffEqGPU, OrdinaryDiffEq
using WGLMakie
using Markdown
using JSServe
using StaticTools
import JSServe.TailwindDashboard as D

Page(exportable=true, offline=true) # for Franklin, you still need to configure
WGLMakie.activate!()

io = IOBuffer()
println(io, "~~~")


app = App() do session
    slider = Slider(0.1:0.1:10)
    menu = D.Dropdown( "",[sin, tan, cos])
    cmap_button = D.Button("change colormap")
    textfield = D.TextField("type in your text")

    inp_1 = D.NumberInput(0.0)
    inp_2 = D.NumberInput(0.0)
    inp_3 = D.NumberInput(0.0)

    cmap = map(cmap_button) do click
    end

    value = map(slider.value) do x
        # return x ^ 2
    end

    fig = surface(rand(4, 4), figure = (resolution = (1800, 1000),))

    slider_grid = DOM.div("z-index: ", slider, slider.value)
    
    return JSServe.record_states(session, DOM.div(fig, slider_grid, menu, DOM.div("x: ",inp_1, "y: ",inp_2 , "z: ",inp_3)))
end

show(io, MIME"text/html"(), app)
println(io, "~~~")
println(String(take!(io)))

```

\textoutput{selv}

\end{section}
