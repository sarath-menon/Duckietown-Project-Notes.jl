# This file was generated, do not modify it. # hide
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