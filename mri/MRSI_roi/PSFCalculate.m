function psf = PSFCalculate(sample,FOV)
% Author: Hoby Hetherington (copied 20200129WF)
% Calculate PSF of CSI acquisition
%  example  PSFCalculate(24,216);

% 
% The PSF point spread function reflects how a single point sample spreads 
% into a distribution through the sampling and reconstruction.
% A point sample at the origin gives all 1s for each k-space sampled since 
% it has no physical size (i.e. phase encoding or read out gradients do not 
% change its amplitude when sampled.
%
% So for 24x24 encoding you get a matrix of 24x24 1s.
% We always filter the data spatially, this is the tanning filter and it is
% applied prior to reconstruction
% Since you use a FOV of 216 and your anatomical images are at 1mm 
% resolution, you use a 216x216 matrix for the final k-space and insert the
% 24x24 hanning filtered data into its center.
% Then you do the FFT (fftshift necessary since the origin is the location
% of maximal value).
%
% The final plot gives you a 1-D projection through the center of the PSF 
% to show how the signal distributes. You can use any cutoff. The
% statistical overlap of two pixels is the integration of the PSF's shifted
% by the amount of pixel separation. Remember it is in 2D.



hann1D = hann(sample,'periodic');
hann2D = hann1D.*hann1D';
figure;
plot(hann1D);

% put 2d hanning centered at middle, middle
startk = FOV/2 - sample/2;
endk = startk + sample -1;
kspace = zeros(FOV,FOV);
kspace(startk:endk,startk:endk)=hann2D;
% generate point spread
psf = fftshift(fftn(fftshift(kspace)));
maxamp = max(max(psf));
levels=100;

% view in 2D
figure;
contour(abs(psf),levels);
grid on;
hold on;
voxsize=FOV/sample;
lower_edge = FOV/2 - voxsize/2;
upper_edge = FOV/2 + voxsize/2;
rectangle('Position', [lower_edge,lower_edge, 9, 9])

% view along one dimension
figure;
plot(abs(psf(:,FOV/2)));
grid on;

thres=60;
plot2(psf, thres, voxsize*2, voxsize*2)
plot2(psf, thres, voxsize, voxsize)

end

function plot2(psf, thres, offset1, offset2)
    levels=100;
    psf2=psf;
    psf2(1:(end-offset1),1:(end-offset2)) = ...
        psf2(1:(end-offset1),1:(end-offset2)) + ...
        psf((offset1+1):end,(offset2+1):end);

    figure
    subplot(1,2,1);
    contour(abs(psf2),levels);
    subplot(1,2,2);
    vals=abs(psf2);
    vals(vals<thres)=0;
    contour(vals,levels);
    title(sprintf('offset (%d,%d) thres=%.02f', offset1, offset2, thres))

end

