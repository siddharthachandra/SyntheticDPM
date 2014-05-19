function newIMG = gridQuantizeModel(im,spaceX,spaceY,spaceZ),

dbstop if error;
[r c d] = size(im);
assert(d==3);
addpath '~/Downloads/vlfeat-0.9.16/toolbox/'
vl_setup;

vertices = double(squeeze(reshape(im,[r*c d])));

binsx = vl_binsearch(spaceX,vertices(:,1));
binsy = vl_binsearch(spaceY,vertices(:,2));
binsz = vl_binsearch(spaceZ,vertices(:,3));
%keyboard;
% combined quantization
partIDS = sub2ind([length(spaceX) length(spaceY) length(spaceZ)],binsx,binsy,binsz);
newIMG = reshape(partIDS,[r c]);
end

