# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
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
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide