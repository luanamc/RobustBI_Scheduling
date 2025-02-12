using DataFrames, CSV
include("params.jl")

"""
Get models parameters
# variables, # binary variables, # binary constraints, # continuous variables, # less than constraints, # equal to constraints, # total constraints
"""
function get_model_parameters(model::Model)

    return DataFrame(num_var = num_variables(model),
                    num_var_bin = num_constraints(model, VariableRef, MOI.ZeroOne), 
                    num_var_bin_const = num_constraints(model, VariableRef, MOI.ZeroOne),
                    num_var_cont_const = num_constraints(model, VariableRef, MOI.GreaterThan{Float64}) + num_constraints(model, VariableRef, MOI.LessThan{Float64}),
                    num_constraints_lessthan = num_constraints(model, AffExpr, MOI.LessThan{Float64}), 
                    num_constraints_equalto = num_constraints(model, AffExpr, MOI.EqualTo{Float64}), 
                    #NonlinearExpr
                    num_constraints = num_constraints(model, AffExpr, MOI.LessThan{Float64}) + num_constraints(model, AffExpr, MOI.EqualTo{Float64})
                )

end

"""
Get solution parameters
if NO_SOLUTION objective bound
else objective bound, objective value, calculated gap
"""
function get_solution_parameters(model::Model)

    if primal_status(model) == NO_SOLUTION

        return DataFrame(objective_bound = objective_bound(model),
                        objective_value = missing,
                        calculate_gap = missing
                    )
    else
        return DataFrame(objective_bound = objective_bound(model),
                        objective_value = objective_value(model),
                        calculate_gap = ((objective_bound(model) - objective_value(model))/objective_bound(model))*100
                    )
    end

end

"""
Get instance parameters
model objective, model name, instance, machines, jobs, constrution time, solve time
"""
function get_instance_parameters(param::Param)

    return DataFrame(model_name = param.model_name,
                    instance = param.instance.file_name,
                    machines = param.instance.n_machine,
                    jobs = param.instance.n_job,
                    construction_time = param.construction_time,
                    solve_time = param.solve_time
                    )
end

"""
Export results
FILENAME-log_result.csv"
"""
function export_results(param::Param)
    
    log_result = get_instance_parameters(param)
    log_result = hcat(log_result, get_model_parameters(param.model))
    if termination_status(param.model) != MEMORY_LIMIT
        log_result = hcat(log_result, get_solution_parameters(param.model))
    end

    # Write logfileresult in csv
    CSV.write(joinpath(param.export_path,param.log_file_name*"_log_result.csv"), log_result)

end
