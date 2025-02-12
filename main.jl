# Define packages
using JuMP, Gurobi
using DataFrames, CSV
using FileIO

# Include self files
include("params.jl")
include("read_dataset.jl")
include("robust_models.jl")
include("export_results.jl")

# Define varaibles
data_import_path = "D:/Data sets (RPMS)/Normal_Congestion"
filenames = readdir(data_import_path)

# Define callback function
data = Any[]
time_limit = .0
model = Model(myGurobi)

function my_callback_function(cb_data, cb_where::Cint)
    if cb_where == GRB_CB_MIP
        runtimeP = Ref{Cdouble}()
        objbstP = Ref{Cdouble}()
        objbndP = Ref{Cdouble}()
        GRBcbget(cb_data, cb_where, GRB_CB_RUNTIME, runtimeP)
        GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBST, objbstP)
        GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBND, objbndP)
        gap = abs((objbstP[] - objbndP[]) / objbstP[])
        push!(data, (runtimeP[], objbstP[], objbndP[], gap[]))
        if runtimeP[] > time_limit
            println(runtimeP[],typeof(runtimeP[]))
            GRBterminate(unsafe_backend(model))
        end
        return
    end
    return
end

for file in filenames
    data = Any[]
    println("============="*file*"===============")
    example = read_instance_file(data_import_path, file)
    if (example.n_machine in [4,6,8] && ((example.n_job/example.n_machine) in [2,3,4]))
        param = Param(instance = example, model_name = "my_model", log_file_name = "my_model_"*file[1:end-4], export_path = "D:/resultados/")
        # param.model, param.construction_time = generate_continuos_formulation__paper_model(example)
        param.model, param.construction_time = generate_bucket_index_precedence_formulation_deterministic_model(example)
        time_limit = param.time_limit
        model = param.model
        param.solve_time = @elapsed begin
            MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)
            optimize!(model)
        end
        param.model = model
        export_results(param)
        data_df = DataFrame(data, [:elapsed_time, :objective_value, :objective_bound, :gap])
        CSV.write(joinpath(param.export_path,param.log_file_name*"_callback_log.csv"), data_df)
    end
end