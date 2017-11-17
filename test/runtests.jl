using SPSRunner
using JuMP, AmplNLWriter

@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

nlp_solvers = [AmplNLSolver(CoinOptServices.couenne), AmplNLSolver(CoinOptServices.bonmin)]
unconstrained_nlp_solver_time = Dict(s=>0.0 for s in nlp_solvers)
constrained_nlp_solver_time = Dict(s=>0.0 for s in nlp_solvers)
solver_to_shortname(solver) = basename(solver.solver_command)

@testset "SPSRunner" begin
    sumWeights = Inf
    @testset "Unconstrained, solver=$(solver_to_shortname(nlp_solver))" for nlp_solver in nlp_solvers
        nEmployees = 4
        emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
        emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), Inf, nEmployees + 1)
        employees = push!(
            [Employee("Limited $i", emp2sched, Inf, i) for i in 1:nEmployees],
            emp3
        )
        schedulingResolution = 1//2

        JuMPModel, x, weights, bsl = formulateJuMPModel(employees, schedulingResolution, nlp_solver)
        @test typeof(JuMPModel) <: JuMP.Model
        @test MathProgBase.numvar(JuMPModel) >= length(bsl.times)
        @test JuMP.getobjectivesense(JuMPModel) == :Max
        @test JuMPModel.internalModelLoaded == false

        status, x1, weights1 = solveJuMPModel!(JuMPModel, x, weights)
        @test JuMPModel.internalModelLoaded == true
        @test status == :Optimal



        # Without a constraint, scheduling everyone to work all the time is optimal.
        sumWeights = sum(weights1)
        @test getobjectivevalue(JuMPModel) == sumWeights
        @test all(isapprox(xi, 1) for xi in x1)

        unconstrained_nlp_solver_time[nlp_solver] = JuMP.getsolvetime(JuMPModel)
    end

    @testset "Constrained, solver=$(solver_to_shortname(nlp_solver))" for nlp_solver in nlp_solvers
        nEmployees = 4
        emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
        emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), 4.0, nEmployees + 1)
        employees = push!(
            [Employee("Limited $i", emp2sched, 1.0, i) for i in 1:nEmployees],
            emp3
        )
        schedulingResolution = 1//2

        JuMPModel, x, weights, bsl = formulateJuMPModel(employees, schedulingResolution, nlp_solver)
        @test typeof(JuMPModel) <: JuMP.Model
        @test MathProgBase.numvar(JuMPModel) >= length(bsl.times)
        @test JuMP.getobjectivesense(JuMPModel) == :Max
        @test JuMPModel.internalModelLoaded == false

        status, x1, weights1 = solveJuMPModel!(JuMPModel, x, weights)
        @test JuMPModel.internalModelLoaded == true
        @test status == :Optimal

        @test getobjectivevalue(JuMPModel) < sumWeights
        constrained_nlp_solver_time[nlp_solver] = JuMP.getsolvetime(JuMPModel)
    end

    @testset "toSchedule" begin
        nEmployees = 4
        emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
        emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), Inf, nEmployees + 1)
        employees = push!(
            [Employee("Limited $i", emp2sched, Inf, i) for i in 1:nEmployees],
            emp3
        )
        schedulingResolution = 1//2

        JuMPModel, x, weights, bsl = formulateJuMPModel(employees, schedulingResolution)

        status, x1, weights1 = solveJuMPModel!(JuMPModel, x, weights)
        @test length(x1) == length(bsl.vec)

        empList1 = toEmployeeList!(bsl, x1)
        @test length(empList1) == length(employees)
        # For an unconstrained problem, everyone should be
        # scheduled during all of their availability.
        @test all(SPSBase.schedules_isapprox(empList1[i].avail, employees[i].avail) for i in 1:length(empList1))
    end

end

println("\n## Unconstrained")
println("| Solver Index | Time |")
for (solver, time) in unconstrained_nlp_solver_time
    println("| ", solver_to_shortname(solver), " | ", time)
end

println("## Constrained")
println("| Solver Index | Time |")
for (solver, time) in constrained_nlp_solver_time
    println("| ", solver_to_shortname(solver), " | ", time)
end