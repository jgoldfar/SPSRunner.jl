VERSION >= v"0.4.0-dev+6521" && __precompile__()
module SPSRunner

using SPSBase
export Schedule, Employee

using JuMP, AmplNLWriter

export formulateAndSolveJuMPModel

function formulateAndSolveJuMPModel(emplist::EmployeeList, increment::Real = 1, solver = CouenneNLSolver())
    m = Model(solver = solver)
    bsl = BitScheduleList(emplist, increment)
    nv = length(bsl.vec)
    np = length(emplist)

    weightMat = SPSBase.generateWeightMat(bsl.times)

    @variable(m, x[1:nv], Bin)
    @variable(m, weights[1:nv], Int)
    for i in 1:nv
        @constraint(m, weights[i] == np + sum(weightMat[j, i] * x[i] for j = 1:nv))
    end
    empInds = SPSBase.getEmployeeIndices(bsl)
    for (i, emp) in enumerate(emplist)
        numPossible = emp.maxTime / increment
        if numPossible == Inf
            continue
        end
        inds = empInds[i]
        @constraint(m, sum(x[j] for j = inds) <= numPossible)
    end
    
    @NLexpression(m, J1, sum(weights[i] * x[i] for i = 1:nv))
    
    @NLobjective(m, Max, J1)

    status = solve(m)

    status, getvalue(x), bsl
end

end # module
