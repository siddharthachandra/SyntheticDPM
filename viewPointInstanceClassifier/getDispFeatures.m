function feat = getDispFeatures(im,sbin),
	imd=im(:,:,1); %assuming grayscale, each channel has the same numbers.
	out=floor(size(imd)/sbin);
	im2=im2blocks(single(imd),sbin,out(1),out(2));
	parameters = [0     4     16     64    256   1024   4096  16384  65536];
	feat = extractDisp(im2,out,parameters,16);
end
