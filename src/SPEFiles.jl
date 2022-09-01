"""
SPEFiles is a librairy aiming at providing utilities to open Princeton
instruments SPE 3.0 files. 

The SPE 3.0 specification can be found
[here](https://raw.githubusercontent.com/hududed/pyControl/master/Manual/LightField/Add-in%20and%20Automation%20SDK/SPE%203.0%20File%20Format%20Specification.pdf).

The library is inspired by the [spe2py](https://github.com/ashirsch/spe2py)
library.

The main exported functions are :
- `SPEFile` to open and read a SPE file.
- `counts` to get the number of counts registered by your detector.
- `exposure` to get the exposure time.
- `wavelength` to get an array storing the wavelengths.

Here is an example of how to use it in practice to plot a file with a single frame and a single region of interest (ROI):

```julia
using SPEFiles

file = SPEFile("myfile.spe")
λ = wavelength(file)
c = counts(file)

using CairoMakie
f, ax, l = lines(λ, c, axis=(xlabel="Wavelength (nm)", ylabel="Counts", title="My spectrim"))
save("myspectrum.png", f)
```
"""
module SPEFiles

using LightXML


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
    # Reading binary data
    seek(io, HEADER_LENGTH)
    frames = SPEFrame{dtype}[]
    for _ in 1:numberofframes
        frame = SPEFrame{dtype}()
        for roi ∈ datablocksregionofinterest
            data = zeros(dtype, roi.width, roi.height)
            read!(io, data)
            push!(frame, data)
        end
        push!(frames, frame)
    end
    SPEFile{dtype}(xml, file_version, frames)
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

Return the number of frames in `f`.
"""
function Base.length(f::SPEFile)
    length(f.frames)
end

"""
    experiment(f::SPEFile)

Returns the xml object corresponding to the experiment used to take data. Refer to the SPE file specification for further information on the structure.
"""
function experiment end
experiment(f::SPEFile) = experiment(f.xml)
function experiment(xml::XMLDocument)
    r = root(xml)
    datahistories = find_element(r, "DataHistories")
    if isnothing(datahistories)
        return missing
    end
    datahistory = find_element(datahistories, "DataHistory")
    find_element(find_element(datahistory, "Origin"), "Experiment")
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
    parse(Float64, content(find_element(shuttertiming, "ExposureTime")))
end

"""
    wavelength(f::SPEFile)

Return the wavelengths as an array.
"""
function wavelength end
wavelength(f::SPEFile) = wavelength(f.xml)
function wavelength(xml::XMLDocument)
    r = root(xml)
    calibrations = find_element(r, "Calibrations")
    if isnothing(calibrations)
        return missing
    end
    λraw = content(find_element(find_element(calibrations, "WavelengthMapping"), "Wavelength"))
    parse.(Float64, split(λraw, ','))
end

"""
    counts(f::SPEFile, [frames, [rois]])

If `frames` is not given, return the first ROI of the first frame. Most of the time, there is only one frame and one ROI, so this function helps keeping things simple, stupid.

If `frames` is given, return the first ROI of the specified frames.

If `rois` is given, return the given `rois` of the given `frames`.
"""
function counts end
counts(f::SPEFile) = f.frames[1][1]
counts(f::SPEFile, frames) = map(x -> f.frames[x][1], frames)
counts(f::SPEFile, frames, rois) = map(x -> f.frames[x][rois], frames)

export SPEFile, experiment, devices, exposure, wavelength, counts

end
