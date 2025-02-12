# Define packages
using JuMP, Gurobi
const GRB_ENV = Gurobi.Env()
myGurobi = ()-> Gurobi.Optimizer(GRB_ENV)

function generate_continuos_formulation__paper_model(instance::InstanceRPMS)
    
    # Instance
    # Set
    M = 1:instance.n_machine # set of machines
    J = 1:instance.n_job # set of jobs
    J_m = [findall(instance.j_m[m] .== 1) for m in M] # set of jobs that can be processed on machine m ∈ M
    M_j = [findall(instance.m_j[j] .== 1) for j in J] # set of suitable machines for j ∈ J
    L = 1:instance.n_job # set of orders
    L_m = [1:instance.NJ_m[m] for m in M] # set of orders that can be processed on machine j ∈ J

    # Parameters
    p_j = instance.p_j
    d_j = instance.d_j
    s_jj = [[0 for j in J] for j in J]
    AdJ_m = instance.AdJ_m
    bigM = 10e+4

    # Initialize model
    construction_time = @elapsed begin
        model = Model(myGurobi)
        # model = direct_model(myGurobi)
        
        # Decision variables
        # Nominal start time for job j ∈ J
        @variable(model, S[J] >= 0)
        # Nominal completion time for job j ∈ J
        @variable(model, C[J] >= 0)
        # Nominal tardiness for job j ∈ J
        # @variable(model, T[J] >= 0)
        # 1, if job j ∈ J the kth job in machine i ∈ I where k ∈ K; 0, otherwise
        @variable(model, x[m in M, j in J, l in L; j in J_m[m]], Bin)
        # Robust variable j ∈ J
        @variable(model, RC[J] >= 0)

        # Minimize completion time
        @objective(model, Min, sum(RC[j] for j in J))

        # Constraints
        for m in M, j in J_m[m], l in L_m[m]
            @constraint(model, 
                [RC[j] - C[j] + bigM*(1 - sum(x[m,j,l]; init=0));
                sum(AdJ_m[m][1]*(p_j[j1]*x[m,j1,l1]) for j1 in J, l1 in 1:l if (j1 in J_m[m]); init=0)] 
                in SecondOrderCone())
        end

        # Calculate Completion time variable
        @constraint(model, completion[j in J],
            S[j] + p_j[j] <= C[j]
        )

        # Avoid overlap between j and j1
        @constraint(model, nooverlap[m in M, j in J, j1 in J, l in L; j!=j1 && j in J_m[m] && j1 in J_m[m] && l in L_m[m][1:end-1]],
            C[j] + s_jj[j][j1] - S[j1] <= bigM*(2 - x[m,j,l] - x[m,j1,l+1])
        )

        # Ensure that a job is executed at once
        @constraint(model, jobexecutedonce[j in J],
            sum(x[m,j,l] for m in M, l in L if j in J_m[m] && l in L_m[m]) == 1
        )

        # Ensure that a machine in one position cannot perform more than one job per time
        @constraint(model, onejobperposition[m in M, l in L; l in L_m[m]],
            sum(x[m,j,l] for j in J if j in J_m[m]) <= 1
        )

        # Ensure that k+1 only be occupied if k is occupied
        @constraint(model, positionconsecutively[m in M, l in L; l in L_m[m][1:end-1]],
            sum(x[m,j,l+1] - x[m,j,l] for j in J if j in J_m[m]) <= 0
        )

    end

    return model, construction_time  # Return the generated model

end

# Bucket-Indexed Precedence Formulation
function generate_bucket_index_precedence_formulation_deterministic_model(instance::InstanceRPMS, percent::Float64)

    # Instance

    # Set
    Δ = minimum(instance.p_j)
    M = 1:instance.n_machine # set of machines
    J = 1:instance.n_job # set of jobs
    J_m = [findall(instance.j_m[m] .== 1) for m in M] # set of jobs that can be processed on machine m ∈ M
    M_j = [findall(instance.m_j[j] .== 1) for j in J] # set of suitable machines for j ∈ J
    P_j, π_j = convert_parameter_to_bucket(instance.p_j, Δ)
    D_j, δ_j = convert_parameter_to_bucket((instance.d_j .-1), Δ)
    B = 1:sum(P_j .+ 1)
    K = 0:1
    AdJ_m = [[percent] for m in 1:instance.n_machine]

    # get variable condition -- without release date and deadline constraints
    exists_u = [(b in B[1:end - P_j[j] - k + 1]) && (π_j[j] < 1.0 || k == 0) && (j in J_m[m]) for m in M, j in J, b in B, k in K]
    exists_e = [(j in J_m[m]) for m in M, j in J, b in B]

    # Initialize model
    construction_time = @elapsed begin
        model = Model(myGurobi)
        # model = direct_model(Gurobi.Optimizer())

        # Decision variables
        # 1, indicates if the machine m executes the job j at bucket b; 0, otherwise
        @variable(model, x[m in M, j in J, b in B, k in K; exists_u[m,j,b,k+1]], Bin)
        # indicates the proportion of bucket b is consumed by the job j
        @variable(model, 0.0 <= u[m in M, j in J, b in B, k in K; exists_u[m,j,b,k+1]] <= 1.0)
        # 1, indicates if the machine m executes the job j at all bucket b; 0, otherwise
        @variable(model, y[m in M, j in J, b in B; exists_e[m,j,b]], Bin)  
        # indicates the proportion of all bucket b is consumed by the job j
        @variable(model, 0.0 <= e[m in M, j in J, b in B; exists_e[m,j,b]] <= 1.0)  
        # indicates the robust completion
        @variable(model, RC[J] >= 0.0)
    
        # Minimize completion time
        @objective(model, Min, sum(RC[j] for j in J))

        # Constraints
        # Ensure that a job is executed at once
        @constraint(model, jobexecutedonce[j in J],
            sum(x[m,j,b,k] for m in M, b in B, k in K if exists_u[m,j,b,k+1]) == 1
        )

        # Lower bound variable u 
        @constraint(model, LBvaru[m in M, j in J, b in B, k in K; exists_u[m,j,b,k+1]],
            ((1 - k)*(1 - π_j[j]) + 1/Δ)*x[m,j,b,k] <= u[m,j,b,k]
        )

        # Upper bound variable u 
        @constraint(model, UBvaru[m in M, j in J, b in B, k in K; exists_u[m,j,b,k+1]],
            u[m,j,b,k] <= (1 - k*π_j[j])*x[m,j,b,k] 
        )

        # variable y #########################################################################################################################
        
        # Ensure that variable y totalize the number of buckets P_j + k occupied by a job
        @constraint(model, ytotal[j in J],
            sum(y[m,j,b] for m in M, b in B if exists_e[m,j,b]) == sum((P_j[j] + k)*x[m,j,b,k] for m in M, b in B, k in K if exists_u[m,j,b,k+1])
        )

        # Ensure that variable y can assume a value if x is allocated for this job
        @constraint(model, yactivedbyx[m in M, j in J, b in B; exists_e[m,j,b]],
            y[m,j,b] <= sum(x[m,j,b1,k] for b1 in B, k in K if exists_u[m,j,b1,k+1]) 
        )

        # Ensure that variable y is equal to 1 from the initial bucket that job is executed
        @constraint(model,LBvary[m in M, j in J, b in B; exists_e[m,j,b]],
            sum(b1*x[m,j,b1,k] for b1 in B, k in K if exists_u[m,j,b1,k+1]) <= b*y[m,j,b] + maximum(B)*(1 - y[m,j,b])
        )

        # Ensure that variable y is equal to 1 to th final bucket that job is executed
        @constraint(model,UBvary[m in M , j in J, b in B; exists_e[m,j,b]],
            b*y[m,j,b] <= sum((b1+P_j[j]+k-1)*x[m,j,b1,k] for b1 in B, k in K if exists_u[m,j,b1,k+1])
        )

        ######################################################################################################################################

        # variable e #########################################################################################################################

        # Ensure that variable e totalize the p_j/Δ = P_j - π_j 
        @constraint(model, etotal[j in J],
            sum(e[m,j,b] for m in M, b in B if exists_e[m,j,b]) == (P_j[j] - π_j[j])*sum(x[m,j,b,k] for m in M, b in B, k in K if exists_u[m,j,b,k+1])
        )

        # Ensure that variable e can assume a value if y is allocated for this job
        @constraint(model, eactivedbyy[m in M, j in J, b in B; exists_e[m,j,b]],
            e[m,j,b] <= y[m,j,b]
        )
        
        # Ensure that variable e in the first bucket assume value of u
        @constraint(model, efirstbucket[m in M, j in J, b in B; exists_e[m,j,b]],
            e[m,j,b] <= sum(u[m,j,b,k] for k in K if exists_u[m,j,b,k+1]) + (1 - sum(x[m,j,b,k] for k in K if exists_u[m,j,b,k+1]))
        )
        
        # Ensure that variable e in the last bucket assume value of (2-k-pi_j) - u 
        @constraint(model, elastbucket[m in M, j in J, b in B[2:end-1]; exists_e[m,j,b] && exists_e[m,j,b-1] && exists_e[m,j,b+1]],
            e[m,j,b] <= sum((2 - k - π_j[j])*x[m,j,b1,k] - u[m,j,b1,k] for b1 in B, k in K if exists_u[m,j,b1,k+1]) + (2 - y[m,j,b-1] - y[m,j,b] + y[m,j,b+1])
        )
        
        # Ensure that variable e in the intermediate buckets assume value of 1
        @constraint(model, eintermediatebucket[m in M, j in J, b in B[2:end-1]; exists_e[m,j,b] && exists_e[m,j,b-1] && exists_e[m,j,b+1]],
            e[m,j,b] >= (y[m,j,b+1] + y[m,j,b-1] - 1)
        )

        ######################################################################################################################################

        # Overlap #########################################################################################################################

        # Ensure that a machine cannot start more than one job per bucket
        @constraint(model, onestartjobperbucket[m in M, b in B],
            sum(x[m,j,b,k] for j in J, k in K if exists_u[m,j,b,k+1]) <= 1
        )

        # Ensure that a machine cannot start more than one job per bucket        
        @constraint(model, notoverlap[m in M, b in B],
        sum(e[m,j,b] for j in J if exists_e[m,j,b]) <= 1
        )

        # Robust #############################################################################################################################
        @expression(model, C[j in J], sum((b + P_j[j] - π_j[j])*x[m,j,b,k] - u[m,j,b,k] for m in M, b in B, k in K if exists_u[m,j,b,k+1]))
        @variable(model, ia[J,J], Bin) # se j tem inicio anterior ao j1

        @constraint(model, inicioanterior[m in M, j in J, j1 in J, b in B],
            sum(x[m,j1,b1,k] for b1 in 1:b, k in K if exists_u[m,j1,b1,k+1]) + sum(x[m,j,b,k] for k in K if exists_u[m,j,b,k+1]) - 1  <= ia[j,j1]
        )

        for m in M, j in J
            @constraint(model, 
                [RC[j] - C[j] + maximum(B)*(1-sum(x[m,j,b,k] for b in B, k in K if exists_u[m,j,b,k+1]; init=0)); # means RC - C - μx
                # RC- C
                sum(AdJ_m[m][1]*(P_j[j1] - π_j[j1])*(ia[j,j1]) for j1 in J; init=0) # means t ≥ ||Px||
                # (P_j - π_j)Δ = p_j
                ] in SecondOrderCone())
        end
        ######################################################################################################################################
   end

    return model, construction_time  # Return the generated model

end

function convert_parameter_to_bucket(parameter::Array{Int64}, bucketSize::Int64)

    parameter_in_bucket = floor.(Int, parameter./bucketSize) .+ 1
    parameter_in_fraction_bucket = parameter_in_bucket .- parameter./bucketSize

    return parameter_in_bucket, parameter_in_fraction_bucket
end