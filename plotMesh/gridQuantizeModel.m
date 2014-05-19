function partIDS = gridQuantizeModel(vertices,widthX,widthY,widthZ),
addpath '~/Downloads/vlfeat-0.9.16/toolbox/'
vl_setup;
minX = min(vertices(:,1));
maxX = max(vertices(:,1));
minY = min(vertices(:,2));
maxY = max(vertices(:,2));
minZ = min(vertices(:,3));
maxZ = max(vertices(:,3));

binsx = vl_binsearch(linspace(minX,maxX,widthX),vertices(:,1));
binsy = vl_binsearch(linspace(minY,maxY,widthY),vertices(:,2));
binsz = vl_binsearch(linspace(minZ,maxZ,widthZ),vertices(:,3));
% combined quantization
partIDS = sub2ind([widthX widthY widthZ],binsy,binsx,binsz) ;
end

