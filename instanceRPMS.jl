struct InstanceRPMS
    file_name::String
    n_job::Int64
    n_machine::Int64
    p_j::Vector{Int64}
    d_j::Vector{Int64}
    m_j::Vector{Vector{Int64}}
    s_jj::Vector{Vector{Int64}}
    j_m::Vector{Vector{Int64}}
    NJ_m::Vector{Int64}
    AdJ_m::Vector{Vector{Float64}}
end