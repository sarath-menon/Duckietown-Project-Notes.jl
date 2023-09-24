# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
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
    n = 10
    index_slider = Slider(1:n)

    X0 =  [0.0]
    X1 = [0.0]

    tspan = (0.0, 5.0)
    parameters = (;τ=0.2)
    
    prob2 = ODEProblem(first_order_sys!, X0, tspan, parameters)
    sol = solve(prob2, Tsit5(), reltol = 1e-8, abstol = 1e-8)
    
    fig = Figure()
    ax = Axis(fig[1, 1])

    y_vec = Observable{Vector{Float64}}([0.])
    

    integ = DiffEqGPU.init(GPUTsit5(), prob.f, false, u0, 0.0, 0.005, p, nothing, CallbackSet(nothing), true, false)
    tres = MallocVector{Float64}(undef,10000)
    u1 = MallocVector{Float64}(undef,10000)
    u2 = MallocVector{Float64}(undef,10000)
    u3 = MallocVector{Float64}(undef,10000)


    t_vec =  collect(Int32(1):Int32(10000))
    lines!(ax, t_vec, y_vec)
    
    on(index_slider) do val  

        # prob = ODEProblem(first_order_sys!, [0.2], tspan, parameters)
        # sol = solve(prob, Tsit5(), reltol = 1e-8, abstol = 1e-8)
        # y_vec[] =  vcat(sol.u...)

        # u0 = @SVector [val; 0.0; 0.0]
        # integ = DiffEqGPU.init(GPUTsit5(), prob.f, false, u0, 0.0, 0.005, p, nothing, CallbackSet(nothing), true, false)

        # for i in Int32(1):Int32(10000)
        #   @inline DiffEqGPU.step!(integ, integ.t + integ.dt, integ.u)
        #   tres[i] = integ.t
        #   u1[i] = integ.u[1]
        #   # u2[i] = integ.u[2]
        #   # u3[i] = integ.u[3]
        # end

        X0 = @SVector [0.0]
        p2 = @SVector [Float64(val) / 10.0]
        integ2 = DiffEqGPU.init(GPUTsit5(), prob2.f, false, X0, 0.0, 0.005, p2, nothing, CallbackSet(nothing), true, false)

        for i in Int32(1):Int32(10000)
          @inline DiffEqGPU.step!(integ2, integ2.t + integ2.dt, integ2.u)
          tres[i] = integ2.t
          u1[i] = integ2.u[1]
          # u2[i] = integ.u[2]
          # u3[i] = integ.u[3]
        end

        y_vec[] = u1
    end
    
    slider = DOM.div("z-index: ", index_slider, index_slider.value)
    return JSServe.record_states(session, DOM.div(slider, fig))
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide