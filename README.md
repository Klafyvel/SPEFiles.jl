# SPEFiles

SPEFiles is a librairy aiming at providing utilities to open Princeton
instruments SPE 3.0 files. 

The SPE 3.0 specification can be found
[here](https://raw.githubusercontent.com/hududed/pyControl/master/Manual/LightField/Add-in%20and%20Automation%20SDK/SPE%203.0%20File%20Format%20Specification.pdf).

The library is inspired by the [spe2py](https://github.com/ashirsch/spe2py)
library, but should provide more features..

## Installation

The library is registered. Use

```julia
] add SPEFiles
```

## Usage

SPEFiles is best served using DataFrames.jl. Open a file like this :

```julia
using SPEFiles, DataFrames

file = SPEFile("myfile.spe")
df = DataFrame(file)
```

You can then simply plot a file like this :

```julia
using CairoMakie
f, ax, l = lines(df.wavelength, df.count, axis=(xlabel="Wavelength (nm)", ylabel="Counts", title="My spectrum"))
save("myspectrum.png", f)
```

The columns of the dataframe are `wavelength`, `count`, `frame`, `roi`, `row`, `column`. You can easily handle complex files with multiple frames and regions of interest, or 2D files, using the DataFrame interface.

If you need metadata of the file, the following functions are useful :

- `SPEFile` to open and read a SPE file.
- `exposure` to get the exposure time.
- `experiment` to get the xml representing the experiment in LightField
- `origin_summary` to get file creator informations
- `devices` to get xml data on the devices

You can also access the XML bits of the file using the `xml` field of the file.
This is an `XMLDocument`, see `LightXML.jl` documentation for how to interact
with it. With that you can retrieve all the experiment parameters used in
LightField.

**This package is under developpment, and I may brake it at some point, even though I'll try not to.**

If you have any feedback on how to improve it, please reach out using the issues
!
