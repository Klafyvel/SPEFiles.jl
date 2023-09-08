using Polynomials

const HDRNAMEMAX=120
const USERINFOMAX = 1000
const COMMENTMAX = 80
const LABELMAX = 16
const FILEVERMAX = 16
const DATEMAX = 10
const ROIMAX = 10
const TIMEMAX = 7

const HEADER_STRUCTURE_VALUES = Dict([
    :ControllerVersion => (T=Int16, offset=0, descr="Hardware Version")
    :LogicOutput => (T=Int16, offset=2, descr="Definition of Output BNC")
    :AmpHiCapLowNoise => (T=UInt16, offset=4, descr="Amp Switching Mode")
    :xDimDet => (T=UInt16, offset=6, descr="Detector x dimension of chip.")
    :mode => (T=Int16, offset=8, descr="timing mode")
    :exp_sec => (T=Float32, offset=10, descr="alternative exposure, in sec.")
    :VChipXdim => (T=Int16, offset=14, descr="Virtual Chip X dim")
    :VChipYdim => (T=Int16, offset=16, descr="Virtual Chip Y dim")
    :yDimDet => (T=UInt16, offset=18, descr="y dimension of CCD or detector.")
    :VirtualChipFlag => (T=Int16, offset=30, descr="On/Off")
    :noscan => (T=Int16, offset=34, descr="Old number of scans - should always be -1")
    :DetTemperature => (T=Float32, offset=36, descr="Detector Temperature Set")
    :DetType => (T=Int16, offset=40, descr="CCD/DiodeArray type")
    :xdim => (T=UInt16, offset=42, descr="actual # of pixels on x axis")
    :stdiode => (T=Int16, offset=44, descr="trigger diode")
    :DelayTime => (T=Float32, offset=46, descr="Used with Async Mode")
    :ShutterControl => (T=UInt16, offset=50, descr="Normal, Disabled Open, Disabled Closed")
    :AbsorbLive => (T=Int16, offset=52, descr="On/Off")
    :AbsorbMode => (T=UInt16, offset=54, descr="Reference Strip or File")
    :CanDoVirtualChipFlag => (T=Int16, offset=56, descr="T/F Cont/Chip able to do Virtual Chip")
    :ThresholdMinLive => (T=Int16, offset=58, descr="On/Off")
    :ThresholdMinVal => (T=Float32, offset=60, descr="Threshold Minimum Value")
    :ThresholdMaxLive => (T=Int16, offset=64, descr="On/Off")
    :ThresholdMaxVal => (T=Float32, offset=66, descr="Threshold Maximum Value")
    :SpecAutoSpectroMode => (T=Int16, offset=70, descr="T/F Spectrograph Used")
    :SpecCenterWlNm => (T=Float32, offset=72, descr="Center Wavelength in Nm")
    :SpecGlueFlag => (T=Int16, offset=76, descr="T/F File is Glued")
    :SpecGlueStartWlNm => (T=Float32, offset=78, descr="Starting Wavelength in Nm")
    :SpecGlueEndWlNm => (T=Float32, offset=82, descr="Starting Wavelength in Nm")
    :SpecGlueMinOvrlpNm => (T=Float32, offset=86, descr="Minimum Overlap in Nm")
    :SpecGlueFinalResNm => (T=Float32, offset=90, descr="Final Resolution in Nm")
    :PulserType => (T=Int16, offset=94, descr="0=None, PG200=1, PTG=2, DG535=3")
    :CustomChipFlag => (T=Int16, offset=96, descr="T/F Custom Chip Used")
    :XPrePixels => (T=Int16, offset=98, descr="Pre Pixels in X direction")
    :XPostPixels => (T=Int16, offset=100, descr="Post Pixels in X direction")
    :YPrePixels => (T=Int16, offset=102, descr="Pre Pixels in Y direction")
    :YPostPixels => (T=Int16, offset=104, descr="Post Pixels in Y direction")
    :asynen => (T=Int16, offset=106, descr="asynchron enable flag 0 = off")
    :datatype => (T=Int16, offset=108, descr="experiment datatype\n0 = Float32 (4 bytes)\n1 = long (4 bytes)\n2 = short (2 bytes)\n3 = unsigned short (2 bytes)")
    :PulserMode => (T=Int16, offset=110, descr="Repetitive/Sequential")
    :PulserOnChipAccums => (T=UInt16, offset=112, descr="Num PTG On-Chip Accums")
    :PulserRepeatExp => (T=UInt32, offset=114, descr="Num Exp Repeats (Pulser SW Accum)")
    :PulseRepWidth => (T=Float32, offset=118, descr="Width Value for Repetitive pulse (usec)")
    :PulseRepDelay => (T=Float32, offset=122, descr="Width Value for Repetitive pulse (usec)")
    :PulseSeqStartWidth => (T=Float32, offset=126, descr="Start Width for Sequential pulse (usec)")
    :PulseSeqEndWidth => (T=Float32, offset=130, descr="End Width for Sequential pulse (usec)")
    :PulseSeqStartDelay => (T=Float32, offset=134, descr="Start Delay for Sequential pulse (usec)")
    :PulseSeqEndDelay => (T=Float32, offset=138, descr="End Delay for Sequential pulse (usec)")
    :PulseSeqIncMode => (T=Int16, offset=142, descr="Increments: 1=Fixed, 2=Exponential")
    :PImaxUsed => (T=Int16, offset=144, descr="PI-Max type controller flag")
    :PImaxMode => (T=Int16, offset=146, descr="PI-Max mode")
    :PImaxGain => (T=Int16, offset=148, descr="PI-Max Gain")
    :BackGrndApplied => (T=Int16, offset=150, descr="1 if background subtraction done")
    :PImax2nsBrdUsed => (T=Int16, offset=152, descr="T/F PI-Max 2ns Board Used")
    :minblk => (T=UInt16, offset=154, descr="min. # of strips per skips")
    :numminblk => (T=UInt16, offset=156, descr="# of min-blocks before geo skps")
    :CustomTimingFlag => (T=Int16, offset=170, descr="T/F Custom Timing Used")
    :ExposUnits => (T=Int16, offset=186, descr="User Units for Exposure")
    :ADCoffset => (T=UInt16, offset=188, descr="ADC offset")
    :ADCrate => (T=UInt16, offset=190, descr="ADC rate")
    :ADCtype => (T=UInt16, offset=192, descr="ADC type")
    :ADCresolution => (T=UInt16, offset=194, descr="ADC resolution")
    :ADCbitAdjust => (T=UInt16, offset=196, descr="ADC bit adjust")
    :gain => (T=UInt16, offset=198, descr="gain")
    :geometric => (T=UInt16, offset=600, descr="geometric ops: rotate 0x01,reverse 0x02,flip 0x04")
    :cleans => (T=UInt16, offset=618, descr="cleans")
    :NumSkpPerCln => (T=UInt16, offset=620, descr="number of skips per clean.")
    :AutoCleansActive => (T=Int16, offset=642, descr="T/F")
    :UseContCleansInst => (T=Int16, offset=644, descr="T/F")
    :AbsorbStripNum => (T=Int16, offset=646, descr="Absorbance Strip Number")
    :SpecSlitPosUnits => (T=Int16, offset=648, descr="Spectrograph Slit Position Units")
    :SpecGrooves => (T=Float32, offset=650, descr="Spectrograph Grating Grooves")
    :srccmp => (T=Int16, offset=654, descr="number of source comp.diodes")
    :ydim => (T=UInt16, offset=656, descr="y dimension of raw data.")
    :scramble => (T=Int16, offset=658, descr="0=scrambled,1=unscrambled")
    :ContinuousCleansFlag => (T=Int16, offset=660, descr="T/F Continuous Cleans Timing Option")
    :ExternalTriggerFlag => (T=Int16, offset=662, descr="T/F External Trigger Timing Option")
    :lnoscan => (T=Int32, offset=664, descr="Number of scans (Early WinX)")
    :lavgexp => (T=Int32, offset=668, descr="Number of Accumulations")
    :ReadoutTime => (T=Float32, offset=672, descr="Experiment readout time")
    :TriggeredModeFlag => (T=Int16, offset=676, descr="T/F Triggered Timing Option")
    :type => (T=Int16, offset=704, descr="1 = new120 (Type II) \n2 = old120 (Type I) \n3 = ST130 \n4 = ST121 \n5 = ST138 \n6 = DC131 (PentaMax) \n7 = ST133 (MicroMax/SpectroMax) \n8 = ST135 (GPIB) \n9 = VICCD \n10 = ST116 (GPIB) \n11 = OMA3 (GPIB) \n12 = OMA4")
    :flatFieldApplied => (T=Int16, offset=706, descr="1 if flat field was applied.")
    :kin_trig_mode => (T=Int16, offset=724, descr="Kinetics Trigger Mode")
    :NumExpRepeats => (T=UInt32, offset=1418, descr="Number of Times experiment repeated")
    :NumExpAccums => (T=UInt32, offset=1422, descr="Number of Time experiment accumulated")
    :YT_Flag => (T=Int16, offset=1426, descr="Set to 1 if this file contains YT data")
    :clkspd_us => (T=Float32, offset=1428, descr="Vert Clock Speed in micro-sec")
    :HWaccumFlag => (T=Int16, offset=1432, descr="set to 1 if accum done by Hardware.")
    :StoreSync => (T=Int16, offset=1434, descr="set to 1 if store sync used")
    :BlemishApplied => (T=Int16, offset=1436, descr="set to 1 if blemish removal applied")
    :CosmicApplied => (T=Int16, offset=1438, descr="set to 1 if cosmic ray removal applied")
    :CosmicType => (T=Int16, offset=1440, descr="if cosmic ray applied, this is type")
    :CosmicThreshold => (T=Float32, offset=1442, descr="Threshold of cosmic ray removal.")
    :NumFrames => (T=Int32, offset=1446, descr="number of frames in file.")
    :MaxIntensity => (T=Float32, offset=1450, descr="max intensity of data (future)")
    :MinIntensity => (T=Float32, offset=1454, descr="min intensity of data future)")
    :ShutterType => (T=UInt16, offset=1474, descr="shutter type.")
    :shutterComp => (T=Float32, offset=1476, descr="shutter compensation time.")
    :readoutMode => (T=UInt16, offset=1480, descr="readout mode, full,kinetics, etc")
    :WindowSize => (T=UInt16, offset=1482, descr="window size for kinetics only.")
    :clkspd => (T=UInt16, offset=1484, descr="clock speed for kinetics & frame transfer")
    :interface_type => (T=UInt16, offset=1486, descr="computer interface (isa-taxi, pci, eisa, etc.)")
    :NumROIsInExperiment => (T=Int16, offset=1488, descr="May be more than the 10 allowed in this header (if 0, assume 1)")
    :controllerNum => (T=UInt16, offset=1506, descr="if multiple controller system will have controller number data came from. This is a future item.")
    :SWmade => (T=UInt16, offset=1508, descr="Which software package created this file")
    :NumROI => (T=Int16, offset=1510, descr="number of ROIs used. if 0 assume 1.")
    :file_header_ver => (T=Float32, offset=1992, descr="version of this file header")
    :WinView_id => (T=Int32, offset=2996, descr="== 0x01234567L if file created by WinX")
])

const HEADER_STRUCTURE_STRINGS = Dict([
    :date => (size=DATEMAX, offset=20, descr="date")
    :Spare_1 => (size=2, offset=32, descr="spare")
    :ExperimentTimeLocal => (size=TIMEMAX,offset=172, descr="Experiment Local Time as hhmmss\0")
    :ExperimentTimeUTC => (size=TIMEMAX, offset=179, descr="Experiment UTC Time as hhmmss\0")
# Comments[5][COMMENTMAX] 200 File Comments
    :xlabel => (size=LABELMAX, offset=602, descr="intensity display string")
    :Spare_2 => (size=10, offset=678, descr="spare")
    :sw_version => (size=FILEVERMAX, offset=688, descr="Version of SW creating this file")
    :Spare_3 => (size=16, offset=708, descr="spare")
    :dlabel => (size=LABELMAX, offset=726, descr="Data label.")
    :Spare_4 => (size=436, offset=742, descr="spare")
    :PulseFileName => (size=HDRNAMEMAX, offset=1178, descr="Name of Pulser File with Pulse Widths/Delays (for Z-Slice)")
    :AbsorbFileName => (size=HDRNAMEMAX, offset=1298, descr="Name of Absorbance File (if File Mode)")
    :ylabel => (size=LABELMAX, offset=1458, descr="y axis label.")
    :Spare_5 => (size=16, offset=1490, descr="spare")
    :FlatField => (size=HDRNAMEMAX, offset=1632, descr="Flat field file name.")
    :background => (size=HDRNAMEMAX, offset=1752, descr="background sub. file name.")
    :blemish => (size=HDRNAMEMAX, offset=1872, descr="blemish file name.")
    :YT_Info => (size=1000, offset=1996, descr="2995 Reserved for YT information")
])

struct ROIInfo
    startx::UInt16
    endx::UInt16
    groupx::UInt16
    starty::UInt16
    endy::UInt16
    groupy::UInt16
end

const HEADER_STRUCTURE_ARRAYS = Dict([
    :SpecMirrorLocation => (T=Int16, size=2, offset=158, descr="Spectro Mirror Location, 0=Not Present")
    :SpecSlitLocation => (T=Int16, size=4, offset=162, descr="Spectro Slit Location, 0=Not Present")
    :SpecMirrorPos => (T=Int16, size=2, offset=622, descr="Spectrograph Mirror Positions")
    :SpecSlitPos => (T=Float32, size=4, offset=626, descr="Spectrograph Slit Positions")
    :ROIInfo => (T=ROIInfo, size=10, offset=1512, descr="ROI informations") 
])

const HEADER_ROI_STARTS = [ 1512, 1524, 1536, 1548, 1560, 1572, 1584, 1596, 1608, 1620 ]

struct Version2 <: SPEVersion
    header::IOBuffer
end

headervalue(f, k) = headervalue(f.metadata, k)
headervalue(v::Version2, k) = headervalue(v.header, k)
function headervalue(io::IO, k)
    if k ∈ keys(HEADER_STRUCTURE_VALUES)
        T,offset,_ = HEADER_STRUCTURE_VALUES[k]
        seek(io, offset)
        read(io, T)
    elseif k ∈ keys(HEADER_STRUCTURE_STRINGS)
        size,offset,_ = HEADER_STRUCTURE_STRINGS[k]
        read_array = zeros(UInt8, size)
        seek(io, offset)
        read!(io, read_array)
        String(read_array)
    elseif k ∈ keys(HEADER_STRUCTURE_ARRAYS)
        T, size, offset, _ = HEADER_STRUCTURE_ARRAYS[k]
        seek(io, offset)
        read_array = Array{T, 1}(undef, size)
        seek(io, offset)
        read!(io, read_array)
        read_array
    else
        error("Unrecognized header key: $k")
    end
end

const HEADER_X_CALIBRATION = Dict([
    :offset => (T=Float64, offset=3000, descr="offset for absolute data scaling")
    :factor => (T=Float64, offset=3008, descr="factor for absolute data scaling")
    :current_unit => (T=Int8, offset=3016, descr="selected scaling unit")
    :reserved1 => (T=Int8, offset=3017, descr="reserved")
    :calib_valid => (T=Int8, offset=3098, descr="flag if calibration is valid")
    :input_unit => (T=Int8, offset=3099, descr="current input units for \"calib_value\"")
    :polynom_unit => (T=Int8, offset=3100, descr="linear UNIT and used in the \"polynom_coeff\"")
    :polynom_order => (T=Int8, offset=3101, descr="ORDER of calibration POLYNOM")
    :calib_count => (T=Int8, offset=3102, descr="valid calibration data pairs")
    :laser_position => (T=Float64, offset=3311, descr="laser wavenumber for relative WN")
    :reserved3 => (T=Int8, offset=3319, descr="reserved")
    :new_calib_flag => (T=UInt8, offset=3320, descr="If set to 200, valid label below")
])

const HEADER_X_CALIBRATION_ARRAYS = Dict([
    :pixel_position => (T=Float64, size=10, offset=3103, descr="pixel pos. of calibration data")
    :calib_value => (T=Float64, size=10, offset=3183, descr="calibration VALUE at above pos")
    :polynom_coeff => (T=Float64, size=6, offset=3263, descr="polynom COEFFICIENTS")
])

const HEADER_X_CALIBRATION_STRINGS = Dict([
    :string => (size=40, offset=3018, descr="special string for scaling")
    :reserved2 => (size=40, offset=3058, descr="reserved")
    :calib_label => (size=81, offset=3321, descr="Calibration label (NULL term'd)")
    :expansion => (size=87, offset=3402, descr="Calibration Expansion area")
])

const HEADER_Y_CALIBRATION = Dict([
    :offset => (T=Float64, offset=3489, descr="offset for absolute data scaling")
    :factor => (T=Float64, offset=3497, descr="factor for absolute data scaling")
    :current_unit => (T=Int8, offset=3505, descr="selected scaling unit")
    :reserved1 => (T=Int8, offset=3506, descr="reserved")
    :calib_valid => (T=Int8, offset=3587, descr="flag if calibration is valid")
    :input_unit => (T=Int8, offset=3588, descr="current input units for \"calib_value\"")
    :polynom_unit => (T=Int8, offset=3589, descr="linear UNIT and used in the \"polynom_coeff\"")
    :polynom_order => (T=Int8, offset=3590, descr="ORDER of calibration POLYNOM")
    :calib_count => (T=Int8, offset=3591, descr="valid calibration data pairs")
    :laser_position => (T=Float64, offset=3800, descr="laser wavenumber for relative WN")
    :reserved3 => (T=Int8, offset=3808, descr="reserved")
    :new_calib_flag => (T=UInt8, offset=3809, descr="If set to 200, valid label below")
])

const HEADER_Y_CALIBRATION_ARRAYS = Dict([
    :pixel_position => (T=Float64, size=10, offset=3592, descr="pixel pos. of calibration data")
    :calib_value => (T=Float64, size=10, offset=3672, descr="calibration VALUE at above pos")
    :polynom_coeff => (T=Float64, size=6, offset=3752, descr="polynom COEFFICIENTS")
])

const HEADER_Y_CALIBRATION_STRINGS = Dict([
    :string => (size=40, offset=3507, descr="special string for scaling")
    :reserved2 => (size=40, offset=3547, descr="reserved")
    :calib_label => (size=81, offset=3810, descr="Calibration label (NULL term'd)")
    :expansion => (size=87, offset=3891, descr="Calibration Expansion area")
])

xcalibration(f, k) = xcalibration(f.metadata, k)
xcalibration(v::Version2, k) = xcalibration(v.header, k)
function xcalibration(io::IO, k)
    if k ∈ keys(HEADER_X_CALIBRATION)
        T,offset,_ = HEADER_X_CALIBRATION[k]
        seek(io, offset)
        read(io, T)
    elseif k ∈ keys(HEADER_X_CALIBRATION_ARRAYS)
        T, size, offset, _ = HEADER_X_CALIBRATION_ARRAYS[k]
        seek(io, offset)
        read_array = Array{T, 1}(undef, size)
        seek(io, offset)
        read!(io, read_array)
        read_array
    elseif k∈ keys(HEADER_X_CALIBRATION_STRINGS)
        size,offset,_ = HEADER_X_CALIBRATION_STRINGS[k]
        read_array = zeros(UInt8, size)
        seek(io, offset)
        read!(io, read_array)
        String(read_array)
    else
        error("Unrecognized x calibration header key: $k")
    end
end

ycalibration(f, k) = ycalibration(f.metadata, k)
ycalibration(v::Version2, k) = ycalibration(v.header, k)
function ycalibration(io::IO, k)
    if k ∈ keys(HEADER_Y_CALIBRATION)
        T,offset,_ = HEADER_Y_CALIBRATION[k]
        seek(io, offset)
        read(io, T)
    elseif k ∈ keys(HEADER_Y_CALIBRATION_ARRAYS)
        T, size, offset, _ = HEADER_Y_CALIBRATION_ARRAYS[k]
        seek(io, offset)
        read_array = Array{T, 1}(undef, size)
        seek(io, offset)
        read!(io, read_array)
        read_array
    elseif k∈ keys(HEADER_Y_CALIBRATION_STRINGS)
        size,offset,_ = HEADER_Y_CALIBRATION_STRINGS[k]
        read_array = zeros(UInt8, size)
        seek(io, offset)
        read!(io, read_array)
        String(read_array)
    else
        error("Unrecognized y calibration header key: $k")
    end
end

const HEADER_END_CALIBRATION = Dict([
    :SpecType => (T=UInt8, offset=4043, descr="spectrometer type (acton, spex, etc.)")
    :SpecModel => (T=UInt8, offset=4044, descr="spectrometer model (type dependent)")
    :PulseBurstUsed => (T=UInt8, offset=4045, descr="pulser burst mode on/off")
    :PulseBurstCount => (T=UInt32, offset=4046, descr="pulser triggers per burst")
    :PulseBurstPeriod => (T=Float64, offset=4050, descr="pulser burst period (in usec)")
    :PulseBracketUsed => (T=UInt8, offset=4058, descr="pulser bracket pulsing on/off")
    :PulseBracketType => (T=UInt8, offset=4059, descr="pulser bracket pulsing type")
    :PulseTimeConstFast => (T=Float64, offset=4060, descr="pulser slow exponential time constant (in usec)")
    :PulseAmplitudeFast => (T=Float64, offset=4068, descr="pulser fast exponential amplitude constant")
    :PulseTimeConstSlow => (T=Float64, offset=4076, descr="pulser slow exponential time constant (in usec)")
    :PulseAmplitudeSlow => (T=Float64, offset=4084, descr="pulser slow exponential amplitude constant")
    :AnalogGain=> (T=Int16, offset=4092, descr="analog gain")
    :AvGainUsed => (T=Int16, offset=4094, descr="avalanche gain was used")
    :AvGain => (T=Int16, offset=4096, descr="avalanche gain value")
    :lastvalue => (T=Int16, offset=4098, descr="Always the LAST value in the header")
])
const HEADER_END_CALIBRATION_STRINGS = Dict([
    :Istring => (size=40, offset=3978, descr="special intensity scaling string")
    :Spare_6 => (size=25, offset=4018, descr="spare")
])

endcalibration(f, k) = endcalibration(f.metadata, k)
endcalibration(v::Version2, k) = endcalibration(v.header, k)
function endcalibration(io::IO, k)
    if k ∈ keys(HEADER_END_CALIBRATION)
        T,offset,_ = HEADER_END_CALIBRATION[k]
        seek(io, offset)
        read(io, T)
    elseif k∈ keys(HEADER_END_CALIBRATION_STRINGS)
        size,offset,_ = HEADER_END_CALIBRATION_STRINGS[k]
        read_array = zeros(UInt8, size)
        seek(io, offset)
        read!(io, read_array)
        String(read_array)
    else
        error("Unrecognized end calibration header key: $k")
    end
end

function SPEFile{Version2, T}(io::IO, version) where {T}
    # roi_infos = headervalue(io, :ROIInfo)
    numberofrois = headervalue(io, :NumROI)
    xdim = headervalue(io, :xdim)
    ydim = headervalue(io, :ydim)
    numberofframes = headervalue(io, :NumFrames)
    # Reading binary data
    seek(io, HEADER_LENGTH)
    frames = SPEFrame{T}[]
    full_frame = Array{T, 2}(undef, xdim, ydim)
    for i in 1:numberofframes
        frame = SPEFrame{T}()
        read!(io, full_frame)
        for j ∈ 1:numberofrois
            # roi = roi_infos[j]
            # width = roi.endx - roi.startx
            # height = roi.endy - roi.starty
            # @info "Hey" width height xdim ydim roi.groupx roi.groupy
            push!(frame, permutedims(full_frame, (2,1)))
        end
        push!(frames, frame)
    end
    header_array = Array{UInt8, 1}(undef, HEADER_LENGTH)
    seek(io, 0)
    read!(io, header_array)
    metadata = Version2(IOBuffer(header_array))
    SPEFile{Version2, T}(frames, version, metadata)
end

Base.size(f::SPEFile{Version2, T}) where {T} = (headervalue(f, :NumFrames), headervalue(f, :NumROI))
exposure(f::SPEFile{Version2, T}) where {T} = headervalue(f, :exp_sec) 
function wavelength(f::SPEFile{Version2, T}) where {T}
    p = Polynomial(xcalibration(f, :polynom_coeff))
    p.(1:headervalue(f, :xdim))
end
