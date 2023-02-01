#!/usr/bin/env julia
# include("view_placements.jl")
# fname="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20210830Luna1/anat.mat";
# viewPlacement.plot_anat_loc(fname)
# anat_orig = viewPlacement.read_anat(fname); orient = viewPlacement.Orient(fname);
# anat=reverse(viewPlacement.rotate_anat(anat_orig, orient.rotm),dims=(1));
# anat[isnan.(anat)] .= 0; Plots.plot(Gray.(anat),xaxis=nothing, yaxis=nothing)
# locs = viewPlacements.get_placements(fname)
#

module viewPlacement
# using Pkg; Pkg.add(["Winston","ColorSchemes","Glob","ReTest","CSV","Colors","Plots"])
using Winston, ColorSchemes, Glob, ReTest, CSV, Plots, Colors
using DelimitedFiles

function test_viewplacements()
  # this probably doesn't work
  viewPlacments.runtests()
end


function nameToLoc(s)
  m = match(r"spectrum\.(\d+)\.(\d+)$", s);
  if m == nothing
    return (0,0)
  end
  return parse.(Int, m.captures[1:2])
end
function get_placements(fname)

  loc_files = Glob.glob("spectrum.[0-9]*[0-9]",dirname(fname));
  if length(loc_files) == 0
      println("MISSING: no spectrum.xxx.yyy files for "*fname) 
      return nothing
  end
  locs = map(nameToLoc, loc_files);
  locs = reduce(hcat, locs) |> transpose;
    
  return locs
end
@testset "get_placments" begin
  locs = get_placements("spectrum/20210225Luna1/anat.mat");
  @test size(locs) == (11,2)
end

function read_anat(fname)
   # little endian 32Float
   # np.fromfile(fp1, '<4f').reshape(res, res).T
    sz = filesize(fname); # 216 * 216 * 4
    anat = Vector{Float32}(undef, convert(Int,sz/4));
    read!(fname, anat);
    anat = reshape(anat, (216,216));
    # flipud (dim=1) and fliplr (dim=2)
    #anat = reverse(anat, dims=(1,2))
    return anat
end

struct Orient
    angle::Float64
    vo::Float64
    ho::Float64
    rotm::Matrix
    function Orient(fname)
        # as saved by SVR1HFinal/WritePositions.m
        orient_file = dirname(fname)*"/orient.txt"
        if ! isfile(orient_file) 
            println("MISSING: no orient.txt for "*fname) 
            return nothing
        end
        orient = CSV.File(orient_file, header=true, transpose=true, normalizenames=true) 
        angle = orient.angle[1]*3.14159/180;
        vo = orient.vert[1];
        ho = orient.horz[1];

        # /ssh:rhea:/opt/ni_tools/matlab_toolboxes/MRRC/SVR1HFinal/TransRotTest.m
        rotm = [ cos(angle)  sin(angle) 0 vo;
                -sin(angle)  cos(angle) 0 ho;
                          0          0  1  0;];

        if any(ismissing.(rotm)) 
            println("ERROR: missing rotm values for " * fname * ". MISSING orient.txt values?") 
            return nothing
        end
        new(angle, vo, ho, rotm);
    end
end
@testset "orient strucut" begin
  o = Orient("spectrum/20210225Luna1/anat.mat");
  @test size(o.rotm) == (3,4)
  @test o.rotm[1,4] == -24
  @test o.vo == 24
  @test o.rotm[2,4] == -23
  @test o.ho == 23
end

function balance_anat(anat)
  mins2 = minimum(anat)*2;
  maxs2 = maximum(anat)/2;
  anat = (anat .- mins2) / (maxs2 .- mins2);
  return anat;
end

function rotate_anat(anat, rotm)
  res=size(anat)[1]; # asssume symetric. probably 216
  # make much wider. repeat 4x216 216 times.
  # each 4x216 has first row for that iteration
  # 1 1 1 1 ..... 2 2 2 ..... 3 3 3 .... 216 216 216...
  basm_first=[ones(1,res);
        collect(1:res)';
        zeros(1,res);
        ones(1,res)];
  basm = repeat(basm_first, 1, res);
  basm[1,:] = repeat(1:res, inner=res);
  xx = rotm*basm; # (3, 46656)
  xx = trunc.(Int, xx); # round to make index
  
  # direct port of matlab code
  # 
  scoutarray = reshape(anat',1,res*res);
  scoutarray2=zeros(res,res);
  for aa=1:res*res
      if xx[1,aa]>=1 &&  xx[2,aa]>=1 &&  xx[2,aa]<=216 && xx[1,aa]<=216
          scoutarray2[xx[1,aa],xx[2,aa]] = scoutarray[aa];
      end
  end
  return balance_anat(scoutarray2)

end
@testset "read_anat" begin
  anat = read_anat("spectrum/20210225Luna1/anat.mat");
  @test minimum(anat) > -500
  @test maximum(anat) < 5000
end


function recon_coords(points, a, vo::Float64, ho::Float64)
    n = size(points)[1]
    new_points = zeros(n,5)
    # directly from ReconCoordinates.m
    new_points[:,1] .= points[:,1].*cos(a) .+ points[:,2].*sin(a) .+vo;
    new_points[:,2] .= points[:,2].*cos(a) .- points[:,1].*sin(a) .+ho;
    # 20230201 - track where these came from and assign an index so we can refer back
    # index used by 3dundump to set roi/atlas/mask value
    # original row/col used to assign back to spectrum file
    new_points[:,3] .= points[:,1]
    new_points[:,4] .= points[:,2]
    new_points[:,5] .= 1:n
    return new_points
end
@testset "transform coord" begin
    points = [10 20; 30 40]
    x = recon_coords(points, 0, 0, 0)
    @test points == x[:,1:2]
    @test points != recon_coords(points, 1, 0, 0)[:,1:2]
end


function plot_placment(anat, locs)
   Winston.colormap(ColorSchemes.bone.colors);
   Winston.imagesc(anat)
   Winston.hold(true);
   Winston.scatter(locs[:,2], locs[:,1], "red")
end
function plotjl_placment(anat, locs, title="")
   anat[isnan.(anat)] .= 0;
   Plots.plot(Gray.(anat),xaxis=nothing, yaxis=nothing, title=title)
   Plots.scatter!(locs[:,2], locs[:,1], markersize=5, legend=false)
end 

function plot_anat_loc(fname)
   anat_orig = read_anat(fname);
   orient = Orient(fname);
   isnothing(orient) && return nothing
   anat = rotate_anat(anat_orig, orient.rotm);
   locs = get_placements(fname);
   isnothing(locs) && return nothing
   # arrange like we see in matlab gui
   # flipud (dim=1) and fliplr (dim=2)
   anat = reverse(anat, dims=(1));
   #locs = abs.(locs .- [216, 0]');
   locs = abs.([0, 216]' .- locs );
   #plot_placment(anat, locs);
   plot = plotjl_placment(anat, locs);
   return plot
end

struct Session
    anat
    orient
    locs
    id
    function Session(fname)
        orient = Orient(fname);
        isnothing(orient) && return nothing
        locs = get_placements(fname);
        isnothing(locs) && return nothing
        anat = read_anat(fname);
        id = match(r"\d{8}Luna\d*",fname).match;
        new(anat, orient, locs, id);
    end
end
function recon_coords(s::Session) 
    return recon_coords(s.locs, s.orient.angle, s.orient.vo, s.orient.ho );
end

function plot_rot_loc(fname)
    s = Session(fname)
    isnothing(s) && return nothing
    locs = recon_coords(s.locs, s.orient.angle, s.orient.vo, s.orient.ho );
    anat = reverse(s.anat, dims=(1));
    anat = balance_anat(anat);
    #locs = abs.(locs .- [216, 0]');
    #plot_placment(anat, locs);
    plot = plotjl_placment(anat, locs[:,1:2], fname);
end

function plot_loc_noadjust(fname)
    s = Session(fname)
    isnothing(s) && return nothing
    anat = reverse(s.anat, dims=(1));
    anat = balance_anat(anat);
    locs = abs.(s.locs .- [216, 0]');
    #plot_placment(anat, locs);
    plot = plotjl_placment(anat, locs);
    return plot
end

# quick func defs
find_anats() = Glob.glob("spectrum/2*Luna*/anat.mat";)
save_name(fname) = "/tmp/Hc_loc_" * match(r"\d{8}Luna\d*",fname).match * ".pdf"

function plot_all()
    for fname in find_anats()
       println("fname=\""*fname*"\"")
       #p = plot_anat_loc(fname)
       p = plot_rot_loc(fname)
       if isnothing(p)
           println("no plot for "*fname)
           continue
       end
       Plots.savefig(save_name(fname)) 
    end
end

function save_loc(s::Session)
    l = recon_coords(s)
    fname = "spectrum/$(s.id)/hc_loc_unrotated.1d"
    writedlm(fname, l)
end

function save_all_locs()
  for fname in find_anats()
    println("fname=\""*fname*"\"")
    s = viewPlacement.Session(fname)
    isnothing(s) && continue 
    save_loc(s)
  end
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    #viewPlacement.plot_all()
    viewPlacement.save_all_locs()
else
    cd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc");
    fname="spectrum/20210225Luna1/anat.mat";
    s = viewPlacement.Session(fname);
    using Plots
    default(show=true);
    pyplot()
    p = viewPlacement.plot_rot_loc(fname)
end
