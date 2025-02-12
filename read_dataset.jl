include("instanceRPMS.jl")

function read_all_filenames(full_path::String)
    filenames = Vector{String}()
    open(full_path, "r") do file
        for line in eachline(file)
            push!(filenames, line)
        end
    end
    return filenames
end

function read_instance_file(root_path::String, file_name::String)
    lines = Vector{String}()
    full_path = joinpath(root_path,file_name)
    open(full_path, "r") do file
        for line in eachline(file)
            push!(lines, line)
        end
    end
    # read the number of machine and job information
    parts = split(lines[1], ";")
    qt_machine = parse(Int, parts[1])
    qt_job = parse(Int, parts[2])
    # println("Number of Jobs: $qt_job \nNumber of machines: $qt_machine")

    # define the set of information
    set_job = lines[2:2+qt_job-1]
    set_machine = lines[2+qt_job:end]

    # get parameters  of job
    p_j = Vector{Int}()
    d_j = Vector{Int}()
    m_j = Vector{Vector{Bool}}()
    s_jj = Vector{Vector{Int}}()
    for j in set_job  
        parts = split(j, ";")
        push!(p_j, parse(Int,parts[3]))
        push!(d_j, parse(Int,parts[4]))
        aux_bool = Vector{Bool}()
        for part in parts[5:5+qt_machine-1]
            push!(aux_bool, parse(Bool,part))
        end
        push!(m_j, aux_bool)
        aux_int = Vector{Int}()
        for part in parts[5+qt_machine:end]
            push!(aux_int, parse(Int,part))
        end
        push!(s_jj, aux_int)
    end
    # println("Processing time: $p_j")
    # println("Due date: $d_j")
    # println("Elegibility: $m_j")
    # println("Setup time: $s_jj")
    j_m = Vector{Vector{Bool}}()
    NJ_m = Vector{Int}()
    AdJ_m = Vector{Vector{Float64}}()
    # get parameters  of machine
    for m in set_machine
        parts = split(m, ";")
        aux_bool = Vector{Bool}()
        for part in parts[3:3+qt_job-1]
            push!(aux_bool, parse(Bool,part))
        end
        push!(j_m, aux_bool)
        push!(NJ_m, parse(Int,parts[3+qt_job+1]))
        aux_float = Vector{Float64}()
        for part in parts[end-3+1:end]
            push!(aux_float, parse(Float64,part))
        end
        push!(AdJ_m, aux_float)
    end
    # println("Elegibility: $j_m")
    # println("NJ: $NJ_m")
    # println("AdJ: $AdJ_m")

    return InstanceRPMS(file_name[1:end-4], qt_job, qt_machine, p_j, d_j, m_j, s_jj, j_m, NJ_m, AdJ_m)
end