module SPEFiles

using LightXML


const XML_FOOTER_OFFSET = 678
const FILE_HEADER_VER = 1992
const DATA_TYPE = 108
const HEADER_LENGTH = 4100


const MIN_VERSION = 3.0

const SPERoi{T} = Array{T, 2}

const SPEFrame{T} = Array{SPERoi{T}, 1}

struct SPEFile{T}
  xml::XMLDocument
  file_version::Float32
  frames::Array{SPEFrame{T}, 1}
end

Base.show(io::IO, x::SPEFile{T}) where T = print(io, "SPEFile{$T} v$(x.file_version), $(length(x.frames)) frame(s)")
#Base.length(x::SPEFile) = length(wavelength(x))

SPEFile(filename::AbstractString) = open(x->SPEFile(x), filename)
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

function Base.size(f::SPEFile)
  (length(f.frames),)
end

function Base.length(f::SPEFile)
  length(f.frames)
end

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


devices(f::SPEFile) = devices(f.xml)
function devices(xml::XMLDocument)
  expe = experiment(xml)
  if ismissing(expe)
    return missing
  end
  find_element(expe, "Devices")
end

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
Most of the time, there is only one frame and one ROI, so this function helps keeping things simple, stupid.
"""
function counts(f::SPEFile)
  f.frames[1][1]
end

function counts(f::SPEFile, frames)
  map(x->f.frames[x][1], frames)
end

function counts(f::SPEFile, frames, rois)
  map(x->f.frames[x][rois], frames)
end

export SPEFile, exposure, wavelength, counts

end
