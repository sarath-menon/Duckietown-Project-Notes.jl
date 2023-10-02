
\begin{section}{title="Components"}

This is an example app to demonstrate how Julia code for DiffEq-type simulations can be compiled for use on the web. This app is built with the following:

* [StaticCompiler](https://github.com/tshort/StaticCompiler.jl) compiles a Julia model to WebAssembly. This uses [GPUCompiler](https://github.com/JuliaGPU/GPUCompiler.jl) which does most of the work. [StaticTools](https://github.com/brenhinkeller/StaticTools.jl) helps with this static compilation.

## Dynamical System
* Effect of the actions do not appear immediately - the behaviour evolves with time
* Eg. To go from 30 km/hr to 60 km/hr in a car we press the accelerator pedal. We know the card doesn't reach 60 km/hr immedately, it takes a few seconds to accelerate to that velocity.


# Mathematical models

* Mathematical Representation of a physical, biological or information system. In this class, we focus on dynamical systems (mostly in state-space form)
* "All models are wrong, but some are useful". Often, a model is an approximation of the real system. The real system might be too complicated to model perfectly. For eg. aerodynamic interactions between the rotor blades of a quadcopter, friction between the tire and ground for a physical robot etc. 
* The required modelling accuracy depends on the application at hand. Eg. aerodynamic drag can be neglected for low-speed control design for quadcopters
* Analysis and design must performed keeping in mind the limitations of the model

## Why models ?

* Simulation
* Controller design
* Verfication and Validaton
* Diagnostics, predictive maintenance


\end{section}

\begin{section}{title="WebAssembly"}

Here is the model with initial conditions that we'll compile. The important part is using [DiffEqGPU](https://github.com/SciML/DiffEqGPU.jl) to set up an integrator. Because it is designed to run on a GPU, it is natural for static compilation. It doesn't allocate or use features from `libjulia`.

\end{section}

\begin{section}{title="Selva"}

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
    slider = Slider(0.1:0.1:10.)

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

    slider_grid = DOM.div("z-index: ", slider, slider.value)

    # interactions
    app = map(slider.value) do val
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
    
    return JSServe.record_states(session,  DOM.div(slider_grid,fig))
    
end


```
\end{showhtml}
\end{section}

\begin{section}{title="WebAssembly"}

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
using GeometryBasics
using FileIO

function meshcube(o=Vec3f(0), sizexyz=Vec3f(1))
    uvs = map(v -> v ./ (3, 2), Vec2f[
        (0, 0), (0, 1), (1, 1), (1, 0),
        (1, 0), (1, 1), (2, 1), (2, 0),
        (2, 0), (2, 1), (3, 1), (3, 0),
        (0, 1), (0, 2), (1, 2), (1, 1),
        (1, 1), (1, 2), (2, 2), (2, 1),
        (2, 1), (2, 2), (3, 2), (3, 1),
    ])
    m = normal_mesh(Rect3f(Vec3f(-0.5) .+ o, sizexyz))
    m = GeometryBasics.Mesh(meta(coordinates(m);
            uv=uvs, normals=normals(m)), faces(m))
end

App() do session
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

    # load mesh 
    crazyflie_stl = load(assetpath(String(@__DIR__) * "/assets/cf2_assembly.obj"))

    # plot cube volume 
    bbox_length = 2
    bbox_width = 2
    bbox_height = 2

    # add floor
    floor_width = 50
    floor_mesh = meshcube(Vec3f(0.5, 0.5, 0.46), Vec3f(bbox_length, bbox_width, 0.01))

    # # show quad 
    # fig = mesh(crazyflie_stl, figure = (resolution = (1200, 1000),))

    fig2 = Figure(resolution = (1200, 1200))
    pl = PointLight(Point3f(0), RGBf(20, 20, 20))
    al = AmbientLight(RGBf(0.2, 0.2, 0.2))
    lscene = LScene(fig2[1, 1], show_axis=false, scenekw = (lights = [pl, al], backgroundcolor=:white, clear=true))
    zoom!(lscene.scene, cameracontrols(lscene.scene), 3)
    update_cam!(lscene.scene, cameracontrols(lscene.scene))

    # now you can plot into lscene like you're used to
    mesh!(crazyflie_stl)

    # # show floor
    # floor = mesh!(floor_mesh; color=:green, interpolate=false)
    # translate!(floor, Vec3f(-bbox_length / 2, -bbox_width / 2, 0))

    slider_grid = DOM.div("z-index: ", slider, slider.value)
    
    return JSServe.record_states(session, DOM.div(fig2, slider_grid, menu, DOM.div("x: ",inp_1, "y: ",inp_2 , "z: ",inp_3)))
end

```

\end{showhtml}
\end{section} 

\begin{section}{title="WebAssembly"}

# Simulation

## Choice of Simulator

## Choice of Integrator Algorithm and Implementation

* Euler forward is the the simplest, but unstable 
* Runga-Kutta 4th order (RK4) is a bit more complcated, but is mich more accurate
* Much fancier algorithms exist (eg. Rosenbrock for stiff ODE's) but RK4 gets the job done most of the time. Popular ODE solvers such Matlab ODE45, scipy ODEint, DIfferentialEquations.jl etc use some fancy version of Rk4 (eg. with adaptive timestepping) as the default algorithm.

## Lockstep Simulation

## Software in the Loop Simulation 

* Duckietown software stack uses Gazebo as defauly simulator 
* Important to differentiate between the simulator and visualizer 

## Hardware in the Loop Simulation 

# Systems Engineering and Architecture

Architecture is design, and design is art. Much better to explain it using a case study basis. Will as reference paper by Lupashin et al 
describing the architecure of the Flying Machine Arena (FMA). Well written, contains wealth of information  

## Everything is a tradeoff

* There's no free lunch in systems engineering. Every decision that you take to improve one aspect will be detrimental to some other aspect. Let's see this with a few examples: 

a) Duckiebot old version had Raspberry Pi, new version Jetson. Much better for iamge processing but what's the downside ? Shorter battery life (mW) comparison and higher cost. Not critical for duckiebot, but super-important in real life applications. Many of you might be familiar with the company Zipline that uses autonomous drones to develop medical supplies. Their flagship platform only a low microcontroller as the flight computer (no high level computers like Raspberry Pi of Jetson). This means that it has much less computing power than the duckibot !. To be fair, it doesn't have cameras, so no heavy image processing. But powerful control methods such as MPC would require something like a Raspberry Pi. So, why stick with the microcontroller when using a Raspberry Pi would enable much better controllers ? Well, you alrready know the answer. The are fighting fro grams and milliwatts to increase the range. Each additional kilometer gained results in a bunch of lives saved.

b) IMU connectected to to microcontroller, which in turn connected to Jetson. IMU communicates via, which is supported by the Jetson. So, why not conect it to the Jetson directly ?

## Trade design study 

Compare factors against each other

## Modularity

* Both and hardware level and software level.For project, all of the hardware and most of the software already provided. Your code would most likely be a couple of nodes that add on to the exsiting software infrastructure. It's worth studying the system architecture for two reasons. You will need to know how the submodules are connected to do the project
* 

## Hardware 

* Not much you can do here, hardware is already

## Co-Design

## Delay Compensation

\end{section} 


