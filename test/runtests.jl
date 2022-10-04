using SPEFiles
using Test, Tables

@testset "SPEFiles.jl" begin
    tbl = SPEFile("test_multiple_rois.spe")

    # test that the MatrixTable `istable`
    @test Tables.istable(typeof(tbl))

    # test that it defines column access
    @test Tables.columnaccess(typeof(tbl))
    @test Tables.columns(tbl) === tbl

    # test that we can access the first "column" of our matrix table by column name
    @test tbl.wavelength isa Vector{Float64}
    @test tbl.count isa Matrix{UInt16}
    @test tbl.frame isa Vector{Int64}
    @test tbl.roi isa Vector{Int64}
    @test tbl.row isa Vector{Int64}
    @test tbl.column isa Vector{Int64}

    # test our `Tables.AbstractColumns` interface methods
    @test Tables.getcolumn(tbl, :wavelength) isa Vector{Float64}
    @test Tables.getcolumn(tbl, :count) isa Matrix{UInt16}
    @test Tables.getcolumn(tbl, :frame) isa Vector{Int64}
    @test Tables.getcolumn(tbl, :roi) isa Vector{Int64}
    @test Tables.getcolumn(tbl, :row) isa Vector{Int64}
    @test Tables.getcolumn(tbl, :column) isa Vector{Int64}
    @test Tables.getcolumn(tbl, 1) isa Vector{Float64}
    @test Tables.getcolumn(tbl, 2) isa Matrix{UInt16}
    @test Tables.getcolumn(tbl, 3) isa Vector{Int64}
    @test Tables.getcolumn(tbl, 4) isa Vector{Int64}
    @test Tables.getcolumn(tbl, 5) isa Vector{Int64}
    @test Tables.getcolumn(tbl, 6) isa Vector{Int64}

    @test Tables.columnnames(tbl) == [
                                      :wavelength
                                      :count
                                      :frame
                                      :roi
                                      :row
                                      :column
                                     ]
end
