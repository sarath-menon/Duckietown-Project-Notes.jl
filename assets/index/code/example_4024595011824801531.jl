# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
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
    tau_slider = Slider(0.1:0.1:10.)

    # variables
    t = MallocVector{Float64}(undef,1000)
    y1 = MallocVector{Float64}(undef,1000)

    # First order system 
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

    slider_grid_1 = DOM.div("Time Constant: ", tau_slider, tau_slider.value)

    # interactions
    app = map(tau_slider.value) do val
        params = (;τ=Float64(val) )

        integ = DiffEqGPU.init(GPUTsit5(), prob2.f, false, X0, 0.0, 0.005, params, nothing, CallbackSet(nothing), true, false)

        for i in Int32(1):Int32(1000)
            t[i] = integ.t
            y1[i] = integ.u[1]
            
            @inline DiffEqGPU.step!(integ, integ.t + integ.dt, integ.u)
          
        end
        
        x_vec[] =  t
        y_vec[] =  y1
    end
    
    return JSServe.record_states(session,  DOM.div(fig, slider_grid_1))
    
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide