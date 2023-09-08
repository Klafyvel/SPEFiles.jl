using LightXML

const XML_FOOTER_OFFSET = 678

struct Version3 <: SPEVersion
    xml::XMLDocument
    frameexposurestarted::Union{Missing,Vector{Int64}}
    frameexposureended::Union{Missing,Vector{Int64}}
end

function SPEFile{Version3, T}(io::IO, version) where {T}
    footer_position = let
        seek(io, XML_FOOTER_OFFSET)
        read(io, UInt64)
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
    frames = SPEFrame{T}[]
    for i in 1:numberofframes
        frame = SPEFrame{T}()
        for roi ∈ datablocksregionofinterest
            data = zeros(T, roi.width, roi.height)
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
    metadata = Version3(xml, exposurestarted, exposureended)
    SPEFile{Version3, T}(frames, version, metadata)
end

xml(f::SPEFile{Version3, T}) where {T} = f.metadata.xml

function Base.size(f::SPEFile{Version3, T}) where {T}
    dataformat = find_element(root(xml(f)), "DataFormat")
    datablockframe = find_element(dataformat, "DataBlock")
    numberofframes = parse(Int, attribute(datablockframe, "count"))
    (numberofframes, length(child_elements(datablockframe)))
end

function Base.length(f::SPEFile{Version3, T}) where {T}
    length(f.frames) .* sum(length.(first(f.frames)))
end

"""
    generalinformation(f::SPEFile{Version3, T})

Return the `GeneralIntormation` tag of the file.
"""
function generalinformation end
generalinformation(f::SPEFile{Version3, T}) where {T} = generalinformation(xml(f))
function generalinformation(xml::XMLDocument)
    r = root(xml)
    e = find_element(r, "GeneralInformation")
    if isnothing(e) missing else e end
end

"""
    notes(f::SPEFile{Version3, T})

Return the notes in the file, if they exist.
"""
function notes end
notes(f::SPEFile{Version3, T}) where {T} = notes(xml(f))
function notes(xml::XMLDocument)
    infos = generalinformation(xml)
    if ismissing(infos)
        return missing
    end
    notes = find_element(infos, "Notes")
    if isnothing(notes)
        missing
    else
        content(notes)
    end
end

"""
    history(f::SPEFile{Version3, T})

Return the history node of the object if it exists.
"""
function history end
history(f::SPEFile{Version3, T}) where {T} = history(xml(f))
function history(xml::XMLDocument)
    r = root(xml)
    datahistories = find_element(r, "DataHistories")
    if isnothing(datahistories)
        return missing
    end
    find_element(datahistories, "DataHistory")
end

""" 
    origin(f::SPEFile{Version3, T})

Return the origin node of the object if it exists.
"""
function origin end
origin(f::SPEFile{Version3, T}) where {T} = origin(xml(f))
function origin(xml::XMLDocument)
    datahistory = history(xml)
    if ismissing(datahistory)
        return missing
    end
    find_element(datahistory, "Origin")
end

"""
    origin_summary(f::SPEFile{Version3, T})

Return a dict with origin metadata for the file. Keys are "software" "creator" "softwareVersion" "softwareCompany" "created"
"""
origin_summary(f::SPEFile{Version3, T}) where {T} = attributes_dict(origin(f))

"""
    experiment(f::SPEFile{Version3, T})

Returns the xml object corresponding to the experiment used to take data. Refer to the SPE file specification for further information on the structure.
"""
function experiment end
experiment(f::SPEFile{Version3, T}) where {T} = experiment(xml(f))
function experiment(xml::XMLDocument)
    orig = origin(xml)
    if ismissing(orig)
        return missing
    end
    find_element(orig, "Experiment")
end

"""
    devices(f::SPEFile{Version3, T})

Returns the xml object corresponding to the devices used in the experiment. Refer to the SPE file specification for further information on the structure.
"""
function devices end
devices(f::SPEFile{Version3, T}) where {T} = devices(xml(f))
function devices(xml::XMLDocument)
    expe = experiment(xml)
    if ismissing(expe)
        return missing
    end
    find_element(expe, "Devices")
end

exposure(f::SPEFile{Version3, T}) where {T} = exposure(xml(f))
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

wavelength(f::SPEFile{Version3, T}) where {T} = wavelength(xml(f))
function wavelength(xml::XMLDocument)
    r = root(xml)
    calibrations = find_element(r, "Calibrations")
    if isnothing(calibrations)
        return missing
    end
    wavelengthmapping = find_element(calibrations, "WavelengthMapping")
    wavelengthnode = find_element(wavelengthmapping, "Wavelength")
    if isnothing(wavelengthnode)
        @debug "Wavelength node not found. Falling back to WavelengthError."
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

export experiment, devices, origin_summary, notes 

