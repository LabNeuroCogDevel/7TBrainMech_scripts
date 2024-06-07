#!/usr/bin/env python3
"""
command line wrapper for glob_func in hurst_nolds
originally used for hard coded input files

pair with 3dROIStats

Also see hurst_nii.py for voxelwise version
"""
from hurst_nolds import glob_func
import nolds
import sys

def run_ts(in_glob, outname, roi_labels=None, func=nolds.dfa, pattern=r'\d{5}_\d{8}'):
    outdf = glob_func(in_glob, roi_labels, func=func, idpatt=pattern)
    outdf.to_csv(outname, quoting=False, index=False)

def parse_in(args):
    import argparse
    parser = argparse.ArgumentParser(description='run nolds hurst on timeseries (eg. maskave or 3dROIstats)')
    parser.add_argument('--input', help="input file or file glob. no header, tab sep. nVolume rows by nROI columns. e.g. from '3dROIStats -1DRformat -quiet ...'", required=True)
    parser.add_argument('--output', help="output csv file", required=True)
    parser.add_argument('--roilabels', help="list of roi labels (if 3dROIstats input file)", nargs="+", default=None)
    parser.add_argument('--method', help="function to derive exponent", choices=["dfa","hurst_rs"], default="dfa")
    parser.add_argument('--pattern', help="regexp to pull ID from 1D filename", default='[0-9]{5}_[0-9]{8}')
    args = parser.parse_args(args)
    if args.method == 'dfa':
        args.method = nolds.dfa
    elif args.method == 'hurst_rs':
        args.method = nolds.hurst_rs
    else:
        raise Exception(f"unknown method {args.method}")
    return args

def main():
    args = parse_in(sys.argv[1:])
    run_ts(args.input, args.output, args.roilabels, args.method, args.pattern)

if __name__ == "__main__":
    main()
    

