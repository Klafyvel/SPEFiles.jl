using Tables

# Tables.jl interface
const COLUMNS_V3 = Symbol.(["wavelength", "count", "frame", "roi", "row", "column", "exposurestarted", "exposureended"])
const COLUMNS_V2 = Symbol.(["wavelength", "count", "frame", "roi", "row", "column"])
Tables.istable(::Type{<:SPEFile}) = true
Tables.schema(::SPEFile{Version3, T}) where {T} = Tables.Schema(
    COLUMNS_V3,
    [Float64, T, Int, Int, Int, Int, Union{Missing, Int64}, Union{Missing, Int64}]
)
Tables.schema(::SPEFile{Version2, T}) where {T} = Tables.Schema(
    COLUMNS_V2,
    [Float64, T, Int, Int, Int, Int]
)
Tables.columnaccess(::Type{<:SPEFile}) = true
Tables.columns(f::SPEFile) = f
function Tables.getcolumn(f::SPEFile{Version2, T}, i::Int) where {T}
    Tables.getcolumn(f, COLUMNS_V2[i])
end
function Tables.getcolumn(f::SPEFile{Version3, T}, i::Int) where {T}
    Tables.getcolumn(f, COLUMNS_V3[i])
end
function Tables.getcolumn(f::SPEFile{Version3, T}, nm::Symbol) where {T}
    if nm == :wavelength
        w = wavelength(f)
        col = Tables.getcolumn(f, :column)
        w[col .+ 1]
    elseif nm == :count
        counts(f)
    elseif nm == :frame
        n_frames = length(f.frames)
        size_one_frame = sum([l for l in length.(first(f.frames))])
        vcat([repeat([i], size_one_frame) for i in 1:n_frames]...)
    elseif nm == :roi
        n_frames = length(f.frames)
        size_rois = length.(first(f.frames))
        rois_id = vcat([repeat([i], l) for (i,l) in enumerate(size_rois)]...)
        repeat(rois_id, n_frames)
    elseif nm == :row
        n_frames = length(f.frames)
        size_rois = size.(first(f.frames))
        row_num = vcat(Iterators.flatten([[repeat([i-1], c) for i in 1:r] for (r,c) in size_rois])...)
        repeat(row_num, n_frames)
    elseif nm == :column
        n_frames = length(f.frames)
        size_rois = size.(first(f.frames))
        col_num = vcat(Iterators.flatten([repeat(0:(c-1), r) for (r,c) in size_rois])...)
        repeat(col_num, n_frames)
    elseif nm == :exposurestarted
        size_one_frame = sum([l for l in length.(first(f.frames))])
        if ismissing(f.metadata.frameexposurestarted)
            repeat([missing], size_one_frame*length(f.frames))
        else
            vcat([repeat([e], size_one_frame) for e in f.metadata.frameexposurestarted]...)       
        end
    elseif nm == :exposureended
        size_one_frame = sum([l for l in length.(first(f.frames))])
        if ismissing(f.metadata.frameexposureended)
            repeat([missing], size_one_frame*length(f.frames))
        else
            vcat([repeat([e], size_one_frame) for e in f.metadata.frameexposureended]...)       
        end
    else
        throw(ArgumentError("Column $nm does not exist for a SPEFile v3."))
    end
end
function Tables.getcolumn(f::SPEFile{Version2, T}, nm::Symbol) where {T}
    if nm == :wavelength
        w = wavelength(f)
        col = Tables.getcolumn(f, :column)
        w[col .+ 1]
    elseif nm == :count
        counts(f)
    elseif nm == :frame
        n_frames = length(f.frames)
        size_one_frame = sum([l for l in length.(first(f.frames))])
        vcat([repeat([i], size_one_frame) for i in 1:n_frames]...)
    elseif nm == :roi
        n_frames = length(f.frames)
        size_rois = length.(first(f.frames))
        rois_id = vcat([repeat([i], l) for (i,l) in enumerate(size_rois)]...)
        repeat(rois_id, n_frames)
    elseif nm == :row
        n_frames = length(f.frames)
        size_rois = size.(first(f.frames))
        row_num = vcat(Iterators.flatten([[repeat([i-1], c) for i in 1:r] for (r,c) in size_rois])...)
        repeat(row_num, n_frames)
    elseif nm == :column
        n_frames = length(f.frames)
        size_rois = size.(first(f.frames))
        col_num = vcat(Iterators.flatten([repeat(0:(c-1), r) for (r,c) in size_rois])...)
        repeat(col_num, n_frames)
    else
        throw(ArgumentError("Column $nm does not exist for a SPEFile v2."))
    end
end
Tables.columnnames(::SPEFile{Version2, T}) where {T} = COLUMNS_V2
Tables.columnnames(::SPEFile{Version3, T}) where {T} = COLUMNS_V3

function Base.getproperty(f::T, sym::Symbol) where {T<:SPEFile}
    if hasfield(T, sym)
        getfield(f, sym)
    else
        Tables.getcolumn(f, sym)
    end
end

function Base.propertynames(::SPEFile{Version2, T}, private::Bool=false) where {T}
    [COLUMNS_V2; fieldnames(SPEFile{T})...]
end

function Base.propertynames(::SPEFile{Version3, T}, private::Bool=false) where {T}
    [COLUMNS_V3; fieldnames(SPEFile{T})...]
end
