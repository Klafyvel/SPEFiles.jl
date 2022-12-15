"""
SPEFiles is a librairy aiming at providing utilities to open Princeton
instruments SPE 3.0 files. 

The SPE 3.0 specification can be found
[here](https://raw.githubusercontent.com/hududed/pyControl/master/Manual/LightField/Add-in%20and%20Automation%20SDK/SPE%203.0%20File%20Format%20Specification.pdf).

The library is inspired by the [spe2py](https://github.com/ashirsch/spe2py)
library.

The main functions are :
- [`SPEFile`](@ref) to open and read a SPE file.
- [`exposure`](@ref) to get the exposure time.
- [`experiment`](@ref) to get the xml representing the experiment in LightField
- [`origin_summary`](@ref) to get file creator informations
- [`devices`](@ref) to get xml data on the devices

Here is an example of how to use it in practice to plot a file with a single frame and a single region of interest (ROI):

```julia
using SPEFiles, DataFrames

file = SPEFile("myfile.spe")
df = DataFrame(file)

using CairoMakie
f, ax, l = lines(df.wavelength, df.count, axis=(xlabel="Wavelength (nm)", ylabel="Counts", title="My spectrum"))
save("myspectrum.png", f)
```
"""
module SPEFiles

using LightXML
using Tables


const XML_FOOTER_OFFSET = 678
const FILE_HEADER_VER = 1992
const DATA_TYPE = 108
const HEADER_LENGTH = 4100

"""
Minimal version of SPE files supported by this package.
"""
const MIN_VERSION = 3.0

"""
Stores a region of interest (ROI). The most general form is a two dimensional array of counts, but the most common form has only one dimension.
"""
const SPERoi{T} = Array{T,2}

"""
Stores the region of interest (ROI) used in a frame.
"""
const SPEFrame{T} = Array{SPERoi{T},1}

struct SPEFile{T}
    xml::XMLDocument
    file_version::Float32
    frames::Array{SPEFrame{T},1}
    frameexposurestarted::Union{Missing,Vector{Int64}}
    frameexposureended::Union{Missing,Vector{Int64}}
end

Base.show(io::IO, x::SPEFile{T}) where {T} = print(io, "SPEFile{$T} v$(x.file_version), $(length(x.frames)) frame(s)")

"""
    SPEFile(filename::AbstractString)

Open the file at `filename` and parse it. Throws an error if the file version is less than $MIN_VERSION.
"""
SPEFile(filename::AbstractString) = open(x -> SPEFile(x), filename)

"""
    SPEFile(io::IO)

Parse the file stored in `io`. Throws an error if the file version is less than $MIN_VERSION.
"""
function SPEFile(io::IO)
    file_version = let
        seek(io, FILE_HEADER_VER)
        read(io, Float32)
    end
    if file_version < MIN_VERSION
        error("SPE file version not handled : $file_version. The minimum version is $MIN_VERSION.")
    end
    footer_position = let
        seek(io, XML_FOOTER_OFFSET)
        read(io, UInt64)
    end
    dtype = let
        seek(io, DATA_TYPE)
        code = read(io, Int16)
        if code == 0
            Float32
        elseif code == 1
            Int32
        elseif code == 2
            Int16
        elseif code == 3
            UInt16
        elseif code == 5
            Float64
        elseif code == 6
            UInt8
        elseif code == 8
            UInt32
        else
            error("SPE File is not using a recognised data type code : $code")
        end
    end
    xml = let
        seek(io, footer_position)
        read(io, String) |> parse_string
    end
    dataformat = find_element(root(xml), "DataFormat")
    datablockframe = find_element(dataformat, "DataBlock")
    numberofframes = parse(Int, attribute(datablockframe, "count"))
    datablocksregionofinterest = [(;
        width=parse(Int, attribute(datablock, "width")),
        height=parse(Int, attribute(datablock, "height")),
        size=parse(Int, attribute(datablock, "size")),
        stride=parse(Int, attribute(datablock, "stride"))
    ) for datablock ∈ child_elements(datablockframe)]
    metaformat = find_element(root(xml), "MetaFormat")
    # LightField only supports metadata per frame, so we should always have only
    # one MetaBlock child.
    metablock = if isnothing(metaformat)
        nothing
    else
        find_element(metaformat, "MetaBlock")
    end

    metadataorder = []
    exposurestartedpresent = false
    exposureendedpresent = false
    # Deciding on a course of action depending on the type of metadata.
    if !isnothing(metablock)
        for metadatatype in child_elements(metablock)
            if name(metadatatype) != "TimeStamp"
                @warn "Your SPE file contains metadata that are not supported by SPEFiles.jl at this time. You may want to open an issue on GitHub." name(metadatatype)
                # In the spec all data types are 8 bytes long.
                push!(metadataorder, (type="skip", size=8))
                continue
            end
            event = attribute(metadatatype, "event")
            push!(metadataorder, (type=event, size=8))
            if event == "ExposureStarted"
                exposurestartedpresent = true
            elseif event == "ExposureEnded"
                exposureendedpresent = true
            else
                @warn "Unsupported timestamp event type, it will be ignored." event
            end
        end
    end
    
    if exposurestartedpresent
        exposurestarted = zeros(Int64, numberofframes)
    else
        exposurestarted = missing
    end
    if exposureendedpresent
        exposureended = zeros(Int64, numberofframes)
    else
        exposureended = missing
    end
    # Reading binary data
    seek(io, HEADER_LENGTH)
    frames = SPEFrame{dtype}[]
    for i in 1:numberofframes
        frame = SPEFrame{dtype}()
        for roi ∈ datablocksregionofinterest
            data = zeros(dtype, roi.width, roi.height)
            read!(io, data)
            push!(frame, permutedims(data, (2,1)))
        end
        push!(frames, frame)
        for metadata in metadataorder
            # Note: I'm assuming timestamps are always integers here.
            if metadata.type == "ExposureStarted"
                exposurestarted[i] = read(io, Int64)
            elseif metadata.type == "ExposureEnded"
                exposureended[i] = read(io, Int64)
            else
                skip(io, metadata.size)
            end
        end
    end
    SPEFile{dtype}(xml, file_version, frames, exposurestarted, exposureended)
end

"""
    size(f::SPEFile)

Return a tuple `(number_of_frames, number_of_rois)`. Note that each region of interest might have its own size.
"""
function Base.size(f::SPEFile)
    dataformat = find_element(root(f.xml), "DataFormat")
    datablockframe = find_element(dataformat, "DataBlock")
    numberofframes = parse(Int, attribute(datablockframe, "count"))
    (numberofframes, length(child_elements(datablockframe)))
end

"""
    length(f::SPEFile)

Return number of frames × ∑_roi length(roi)
"""
function Base.length(f::SPEFile)
    length(f.frames) .* sum(length.(first(f.frames)))
end

"""
    history(f::SPEFile)

Return the history node of the object if it exists.
"""
function history end
history(f::SPEFile) = history(f.xml)
function history(xml::XMLDocument)
    r = root(xml)
    datahistories = find_element(r, "DataHistories")
    if isnothing(datahistories)
        return missing
    end
    find_element(datahistories, "DataHistory")
end

""" 
    origin(f::SPEFile)

Return the origin node of the object if it exists.
"""
function origin end
origin(f::SPEFile) = origin(f.xml)
function origin(xml::XMLDocument)
    datahistory = history(xml)
    if ismissing(datahistory)
        return missing
    end
    find_element(datahistory, "Origin")
end

"""
    origin_summary(f::SPEFile)

Return a dict with origin metadata for the file. Keys are "software" "creator" "softwareVersion" "softwareCompany" "created"
"""
origin_summary(f::SPEFile) = attributes_dict(origin(f))

"""
    experiment(f::SPEFile)

Returns the xml object corresponding to the experiment used to take data. Refer to the SPE file specification for further information on the structure.
"""
function experiment end
experiment(f::SPEFile) = experiment(f.xml)
function experiment(xml::XMLDocument)
    orig = origin(xml)
    if ismissing(orig)
        return missing
    end
    find_element(orig, "Experiment")
end

"""
    devices(f::SPEFile)

Returns the xml object corresponding to the devices used in the experiment. Refer to the SPE file specification for further information on the structure.
"""
function devices end
devices(f::SPEFile) = devices(f.xml)
function devices(xml::XMLDocument)
    expe = experiment(xml)
    if ismissing(expe)
        return missing
    end
    find_element(expe, "Devices")
end

"""
    exposure(f::SPEFile)

Return the exposure used in the experiment.

!!! warning
    This does not work when multiple camreas are being used. An error is thrown in that case.
"""
function exposure end
exposure(f::SPEFile) = exposure(f.xml)
function exposure(xml::XMLDocument)
    dev = devices(xml)
    if ismissing(dev)
        return missing
    end
    cameras = find_element(dev, "Cameras")
    if parse(Int, attribute(cameras, "count")) > 1
        error("Exposure is not implemented for multiple cameras.")
    end
    camera = find_element(cameras, "Camera")
    shuttertiming = find_element(camera, "ShutterTiming")
    exposuretime = find_element(shuttertiming, "ExposureTime")
    parse(Float64, content(exposuretime))
end

"""
    wavelength(f::SPEFile)

Return the wavelengths as an array.

!!! warning "Deprecated"
    This function is deprecated and will no longer be exported in the future.
    You should rather use the Tables.jl interface.

"""
function wavelength end
wavelength(f::SPEFile) = wavelength(f.xml)
function wavelength(xml::XMLDocument)
    r = root(xml)
    calibrations = find_element(r, "Calibrations")
    if isnothing(calibrations)
        return missing
    end
    wavelengthmapping = find_element(calibrations, "WavelengthMapping")
    wavelengthnode = find_element(wavelengthmapping, "Wavelength")
    if isnothing(wavelengthnode)
        @warn "Wavelength node not found. Falling back to WavelengthError."
        wavelengthnode = find_element(wavelengthmapping, "WavelengthError")
        if isnothing(wavelengthnode)
            error("No wavelength found.")
        end
        λraw = content(wavelengthnode)
        parse.(Float64, map(x->first(split(x, ',')), split(λraw, ' ')))
    else
        λraw = content(wavelengthnode)
        parse.(Float64, split(λraw, ','))
    end
end

"""
    counts(f::SPEFile, [frames, [rois]])

If `frames` is not given, return the counts for all frames and rois.

If `frames` is given, return the first ROI of the specified frames.

If `rois` is given, return the given `rois` of the given `frames`.

!!! warning "Deprecated"
    This function is deprecated and will no longer be exported in the future.
    You should rather use the Tables.jl interface.

"""
function counts end
counts(f::SPEFile) = vcat(reshape.(Iterators.flatten(f.frames), :, 1)...)
counts(f::SPEFile, frames) = map(x -> f.frames[x][1], frames)
counts(f::SPEFile, frames, rois) = map(x -> f.frames[x][rois], frames)

# Tables.jl interface
const COLUMNS = Symbol.(["wavelength", "count", "frame", "roi", "row", "column", "exposurestarted", "exposureended"])
Tables.istable(::Type{<:SPEFile}) = true
Tables.schema(::SPEFile{T}) where {T} = Tables.Schema(
    COLUMNS,
    [Float64, T, Int, Int, Int, Int, Union{Missing, Int64}, Union{Missing, Int64}]
)
Tables.columnaccess(::Type{<:SPEFile}) = true
Tables.columns(f::SPEFile) = f
function Tables.getcolumn(f::SPEFile, i::Int) 
    Tables.getcolumn(f, COLUMNS[i])
end
function Tables.getcolumn(f::SPEFile, nm::Symbol)
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
        if ismissing(f.frameexposurestarted)
            repeat([missing], size_one_frame*length(f.frames))
        else
            vcat([repeat([e], size_one_frame) for e in f.frameexposurestarted]...)       
        end
    elseif nm == :exposureended
        size_one_frame = sum([l for l in length.(first(f.frames))])
        if ismissing(f.frameexposureended)
            repeat([missing], size_one_frame*length(f.frames))
        else
            vcat([repeat([e], size_one_frame) for e in f.frameexposureended]...)       
        end
    else
        throw(ArgumentError("Column $nm does not exist for a SPEFile."))
    end
end
Tables.columnnames(::SPEFile) = COLUMNS

function Base.getproperty(f::T, sym::Symbol) where {T<:SPEFile}
    try
        Tables.getcolumn(f, sym)
    catch e
        if e isa ArgumentError 
            getfield(f, sym)
        else
            rethrow(e)
        end
    end
end

function Base.propertynames(::SPEFile{T}, private::Bool=false) where {T}
    [COLUMNS; fieldnames(SPEFile{T})...]
end

export SPEFile, experiment, devices, exposure, wavelength, counts, origin_summary

end
