#############################################################################
# JuMP
# An algebraic modelling langauge for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################
# sudoku.jl
# A sudoku solver that uses a MIP to find solutions
#
# We have binary variables x[i,j,k] which, if = 1, say that cell (i,j)
# contains the number k
# The constraints are:
# 1 - Each row contains each number exactly once
# 2 - Each column contains each number exactly once
# 3 - Each 3x3 subgrid contains each number exactly once
# and the obvious one that
# 4 - Each cell has one value only
# We will take the initial grid as a CSV file, where 0s are "blanks
#############################################################################

using JuMP

# Load data
function LoadData(filepath)
    fp = open(filepath, "r")
    initgrid = zeros(Int,9,9)
    for row in 1:9
        line = readline(fp)
        initgrid[row,:] = int(split(line,","))
    end
    return initgrid
end

# Solve model
function SolveModel(initgrid)
    m = Model()

    @defVar(m, 0 <= x[1:9, 1:9, 1:9] <= 1, Int)

    # Constraint 1 - Each row...
    @addConstraint(m, row[i=1:9,val=1:9], sum(x[i,:,val]) == 1)
    # Constraint 2 - Each column...
    @addConstraint(m, col[j=1:9,val=1:9], sum(x[:,j,val]) == 1)

    # Constraint 3 - Each sub-grid...
    @addConstraint(m, subgrid[i=1:3:7,j=1:3:7,val=1:9], sum(x[i:i+2,j:j+2,val]) == 1)

    # Constraint 4 - Cells...
    @addConstraint(m, cells[i=1:9,j=1:9], sum(x[i,j,:]) == 1)

    # Initial solution
    for row in 1:9
        for col in 1:9
            if initgrid[row,col] != 0
                @addConstraint(m, x[row, col, initgrid[row, col]] == 1)
            end
        end
    end

    # Solve it
    status = solve(m)
    
    # Check solution
    if status == :Infeasible
        error("No solution found!")
    else
        mipSol = getValue(x)
        sol = zeros(Int,9,9)
        for row in 1:9, col in 1:9, val in 1:9
            if mipSol[row, col, val] >= 0.9
                sol[row, col] = val
            end
        end
        return sol
    end

end

# Initialization
if length(ARGS) != 1
    error("Expected one argument: the initial solution, e.g. julia sudoku.jl sudoku.csv")
end

# Solve
sol = SolveModel(LoadData(ARGS[1]))

# Display solution
println("Solution:")
println("[-----------------------]")
for row in 1:9
    print("[ ")
    for col in 1:9
        print("$(sol[row,col]) ")
        if col % 3 == 0 && col < 9
            print("| ")
        end
    end
    println("]")
    if row % 3 == 0
        println("[-----------------------]")
    end
end

