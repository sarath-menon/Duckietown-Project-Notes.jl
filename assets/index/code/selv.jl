# This file was generated, do not modify it. # hide
#hideall

using StaticArrays
using DiffEqGPU, OrdinaryDiffEq
using WGLMakie
using Markdown
using JSServe
using StaticTools
import JSServe.TailwindDashboard as D
using GeometryBasics

Page(exportable=true, offline=true) # for Franklin, you still need to configure
WGLMakie.activate!()

io = IOBuffer()
println(io, "~~~")

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

    # load mesh 
    crazyflie_stl = load(assetpath(String(@__DIR__) * "/assets/cf2_assembly.obj"))

    # plot cube volume 
    bbox_length = 2
    bbox_width = 2
    bbox_height = 2

    # add floor
    floor_width = 50
    floor_mesh = meshcube(Vec3f(0.5, 0.5, 0.46), Vec3f(bbox_length, bbox_width, 0.01))

    # show quad 
    fig = mesh(crazyflie_stl, figure = (resolution = (1800, 1000),))

    # # show floor
    # floor = mesh!(floor_mesh; color=:green, interpolate=false)
    # translate!(floor, Vec3f(-bbox_length / 2, -bbox_width / 2, 0))

    slider_grid = DOM.div("z-index: ", slider, slider.value)
    
    return JSServe.record_states(session, DOM.div(fig, slider_grid, menu, DOM.div("x: ",inp_1, "y: ",inp_2 , "z: ",inp_3)))
end

show(io, MIME"text/html"(), app)
println(io, "~~~")
println(String(take!(io)))