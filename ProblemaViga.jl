using JuMP, Ipopt, LinearAlgebra, Plots

L = 500                             #Tamanho da viga em cm
N = 15                              #Número de segmentos
P = 50000                           #Carga pontual em Newtons
E = 200                             #Módulo da elasticidade
Lj = (L/N)                          #Tamanho de cada segmento
Tm = 14000                          #Tensão Máxima
ymax = 0.5                          #Deslocamento máximo

function CustoConcreto(x) 
                    if x ≤ 10
                        f = 300*x
                    else x > 10
                        f = 260*x
                    end
    return f
end

model = Model(with_optimizer(Ipopt.Optimizer, max_iter=3000))
optimizer = Ipopt.Optimizer
nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)

JuMP.register(model, :CustoConcreto, 1, CustoConcreto, autodiff=true)

@variable(model, b[i=1:N] >= 0.1)
@variable(model, h[i=1:N] >=0.1)
@variable(model, m[i=0:N] >= 0.1)
@variable(model, y[i=0:N] >= 0.1)
@variable(model, t[i=1:N] >= 0.1)
fix(y[0], 0; force = true)
fix(m[0], 0; force = true)



@NLobjective(model, Min, (CustoConcreto(sum((b[j]*h[j]*Lj) for j = 1:N)) + (0.175*(0.0099*(((sum((b[j]*h[j]*Lj) for j = 1:N)*2500)/(P)))+0.0013)/(90) + (0.13)/(90)) * (sum((b[j]*h[j]*Lj) for j = 1:N) * 3.9 * 7850)))

@NLconstraint(model, [i=1:N], (((P*(2*Lj))*h[i])/(2*((b[i]*h[i]^3)/(12)))) / Tm <= 1 )

@NLconstraint(model, [i=1:N], m[i] == (((P*(Lj))/(E*(b[i]*(h[i])^3)/(12))) * ((L -  Lj*(i)) + (Lj)/(2))) + m[i-1])
@NLconstraint(model, [i=1:N], y[i] == (((P*(Lj^2))/(2*E*(b[i]*(h[i])^3)/(12))) * ((L -  Lj*(i)) + (2*Lj)/(3))) + m[i-1]*(Lj) + y[i-1])
@NLconstraint(model, (y[N] / ymax) -1 <= 0)

@NLconstraint(model, [i=1:N], h[i] - 20*b[i] <= 0)
@NLconstraint(model, sum(b[j]*h[j]*Lj for j = 1:N) <= 2.0e7)
@NLconstraint(model, [i=1:N],  b[i] <= h[i])

print(model)
optimize!(model)


h, b = value.(h), value.(b)

rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
p = plot()
plot!(p, rectangle(Lj/100,h[1]/100,0,0), opacity=.5, leg=false, xlims = (0,6), ylims = (0,6))
for i = 2 : N
plot!(p, rectangle(Lj/100,h[i]/100,(i-1)*(Lj/100),((h[1]-h[i])/100)), opacity=.5, leg=false, xlims = (0,6), ylims = (0,4))
end
plt = plot(p)
