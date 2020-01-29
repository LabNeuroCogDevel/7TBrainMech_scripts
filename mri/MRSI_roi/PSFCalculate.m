function PSFCalculate(sample,FOV)
% Author: Hoby Hetherington (c/o WF 20200129)
% Calculate PSF of CSI acquisition
%  example  PSFCalculate(24,216);


kspace(1:FOV,1:FOV)=0;
hann1(1:sample) = hann(sample,'periodic');
hann2(1:sample) = hann(sample,'periodic');
hann2D = hann1.*hann2';
figure;
plot(hann1);
startk = FOV/2 - sample/2;
endk = startk + sample -1;
kspace(startk:endk,startk:endk)=hann2D;

psf = fftshift(fftn(fftshift(kspace)));
figure;
maxamp = max(max(psf));
levels=10;
contour(abs(psf),levels);

grid on;
figure;
plot(abs(psf(:,FOV/2)));
grid on;

end