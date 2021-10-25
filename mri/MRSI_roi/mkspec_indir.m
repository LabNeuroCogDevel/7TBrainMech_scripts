function mkspec_indir(varargin)
% use gen_spectrum in a given directory (or cwd) 
if(length(which('gen_spectrum'))<=0), addpath('/opt/ni_tools/MRSIcoord.py/matlab'), end
if(length(which('gen_spectrum'))<=0), error('cannot find function "gen_spectrum"'), end


if nargin >= 1, cd(varargin{1}), end
if length(dir('spectrum*'))>0, error('already have "%s/spectrum*" files',pwd), end
siarray='../../raw/siarray.1.1';
if ~exist(siarray, 'file'), error('no %s/%s',pwd,siarray), end
if ~exist('sid3_picked_coords.txt', 'file'), error('no sid3_picked_coords.txt'), end
posl = load('sid3_picked_coords.txt');

gen_spectrum(siarray, 216, posl, './')
end
