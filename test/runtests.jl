using SPSRunner
using JuMP, AmplNLWriter

@static if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

nlp_solvers = [CouenneNLSolver(), BonminNLSolver()]
unconstrained_nlp_solver_time = Dict(s=>0.0 for s in nlp_solvers)
constrained_nlp_solver_time = Dict(s=>0.0 for s in nlp_solvers)

# write your own tests here
@testset "SPSRunner" begin
    sumWeights = Inf
    @testset "Unconstrained, solver=$nlp_solver" for nlp_solver in nlp_solvers
        nEmployees = 4
        emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
        emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), Inf, nEmployees + 1)
        employees = push!(
            [Employee("Limited $i", emp2sched, Inf, i) for i in 1:nEmployees],
            emp3
        )
        schedulingResolution = 1//2

        status, x, bsl = formulateAndSolveJuMPModel(employees, schedulingResolution, nlp_solver)
        @test typeof(JuMPModel) <: JuMP.Model
        @test MathProgBase.numvar(JuMPModel) >= length(bsl.times)
        @test JuMP.getobjectivesense(JuMPModel) == :Max
        @test status == :Optimal
        @test JuMPModel.internalModelLoaded == true

        # Without a constraint, scheduling everyone to work all the time is optimal.
        sumWeights = sum(weights)
        @test getobjectivevalue(JuMPModel) == sumWeights
        @test all(isapprox(xi, 1) for xi in x)

        unconstrained_nlp_solver_time[nlp_solver] = JuMP.getsolvetime(JuMPModel) 
    end
    
    @testset "Constrained, solver=$nlp_solver" for nlp_solver in nlp_solvers
        nEmployees = 4
        emp2sched = Schedule([(8, 10)], [(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)])
        emp3 = Employee("Limited $(nEmployees + 1)", Schedule([(0, 0)], [(8, 10), (12, 13)], [(0, 0)], [(8, 10)], [(0, 0)]), 4.0, nEmployees + 1)
        employees = push!(
            [Employee("Limited $i", emp2sched, 1.0, i) for i in 1:nEmployees],
            emp3
        )
        schedulingResolution = 1//2

        status, x, bsl = formulateAndSolveJuMPModel(employees, schedulingResolution, nlp_solver)
        @test typeof(JuMPModel) <: JuMP.Model
        @test MathProgBase.numvar(JuMPModel) >= length(bsl.times)
        @test JuMP.getobjectivesense(JuMPModel) == :Max
        @test status == :Optimal
        @test JuMPModel.internalModelLoaded == true

        @test getobjectivevalue(JuMPModel) < sumWeights
        constrained_nlp_solver_time[nlp_solver] = JuMP.getsolvetime(JuMPModel) 
    end

    println("## Unconstrained")
    println("| Solver Index | Time |")
    for (solver, time) in unconstrained_nlp_solver_time
        println("| ", basename(solver.solver_command), " | ", time)
    end

    println("## Constrained")
    println("| Solver Index | Time |")
    for (solver, time) in constrained_nlp_solver_time
        println("| ", basename(solver.solver_command), " | ", time)
    end
end