using Parameters
using JuMP

# Include self files
include("instanceRPMS.jl")

@with_kw mutable struct Param
    instance::InstanceRPMS = InstanceRPMS()
    model_name::String = ""
    time_limit::Float64 = 3600.0
    model::Model = Model()
    construction_time::Float64  = 0.0
    solve_time::Float64  = 0.0
    log_file_name::String = ""
    import_path::String = ""
    export_path::String = ""
end
