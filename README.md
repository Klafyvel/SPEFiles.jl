# SPEFiles

SPEFiles is a librairy aiming at providing utilities to open Princeton
instruments SPE 3.0 files. 

The SPE 3.0 specification can be found
[here](https://raw.githubusercontent.com/hududed/pyControl/master/Manual/LightField/Add-in%20and%20Automation%20SDK/SPE%203.0%20File%20Format%20Specification.pdf).

The library is inspired by the [spe2py](https://github.com/ashirsch/spe2py)
library.

## Installation

The library is not yet registered. Use

```julia
] add https://github.com/Klafyvel/SPEFiles.jl
```

## Usage

Open a file like this :

```julia
file = SPEFile("myfile.spe")
```

You can then access the `exposure` and `wavelength` of you spectra using the two
functions with the same names.

If your spectrum is a simple spectrum, you can retrieve it using the `counts`
function.

If your spectrum is more complicated (*e.g.* multiple frames, roi or 2D pixel
images), you can use the `frames` field of the file, which contains several
regions of interest (ROI).

You can also access the XML bits of the file using the `xml` field of the file.
This is an `XMLDocument`, see `LightXML.jl` documentation for how to interact
with it. With that you can retrieve all the experiment parameters used in
LightField.

**This package is under developpment, and I may brake it at some point, even though I'll try not to.**

If you have any feedback on how to improve it, please reach out using the issues
!
