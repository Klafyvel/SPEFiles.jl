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

const FILE_HEADER_VER = 1992
const DATA_TYPE = 108
const HEADER_LENGTH = 4100

"""
Minimal version of SPE files supported by this package.
"""
const MIN_VERSION = 3.0

abstract type SPEVersion end


"""
Stores a region of interest (ROI). The most general form is a two dimensional array of counts, but the most common form has only one dimension.
"""
const SPERoi{T} = Array{T,2}

"""
Stores the region of interest (ROI) used in a frame.
"""
const SPEFrame{T} = Array{SPERoi{T},1}

struct SPEFile{V,T}
    frames::Array{SPEFrame{T},1}
    version::Float32
    metadata::V
end

fileversion(f::SPEFile) = f.version 

Base.show(io::IO, x::SPEFile{V,T}) where {V,T} = print(io, "SPEFile{$V, $T} v$(fileversion(x)), $(length(x.frames)) frame(s)")

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
    if file_version ≥ 3.0
        SPEFile{Version3, dtype}(io, file_version)
    elseif 2.0 ≤ file_version < 3.0
        SPEFile{Version2, dtype}(io, file_version)
    else
        # pre 2.0 is documented here: https://nstx.pppl.gov/DragNDrop/Operations/Diagnostics_&_Support_Sys/VIPS/WinSpec%202.6%20Spectroscopy%20Software%20User%20Manual.pdf
        error("SPEFiles.jl does not handle pre-2.0 file formats. Please open an issue on GitHub if you want us to support this format.")
    end
end

"""
    size(f::SPEFile)

Return a tuple `(number_of_frames, number_of_rois)`. Note that each region of interest might have its own size.
"""
function Base.size(_::SPEFile) end

"""
    length(f::SPEFile)

Return number of frames × ∑_roi length(roi)
"""
function Base.length(_::SPEFile) end

"""
    exposure(f::SPEFile)

Return the exposure used in the experiment.

!!! warning
    This does not work when multiple camreas are being used. An error is thrown in that case.
"""
function exposure end

"""
    wavelength(f::SPEFile)

Return the wavelengths as an array.

!!! warning "Deprecated"
    This function is deprecated and will no longer be exported in the future.
    You should rather use the Tables.jl interface.

"""
function wavelength end

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
counts(f::SPEFile)= vcat(reshape.(Iterators.flatten(f.frames), :, 1)...)
counts(f::SPEFile, frames) = map(x -> f.frames[x][1], frames)
counts(f::SPEFile, frames, rois) = map(x -> f.frames[x][rois], frames)

include("spe3.jl")
include("spe2.jl")
include("tables.jl")

export SPEFile, exposure, wavelength, counts

end
