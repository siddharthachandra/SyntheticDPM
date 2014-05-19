%% preparation. getting fronto parallel.
addpath toolbox_graph
categories = {'monitortelevision'}%,'bed','chair','sofa','table'}
numC = length(categories);

parm.sizeRoot = [10 10];
parm.sizeParts = [3 3];
parm.sbin = 8;
parm.numViews = 4; %front, rear, two side-views. 
parm.numParts = prod(parm.sizeRoot - parm.sizeParts + 1);
small = 1e-4;
Xaxis = [0 1 0];
Yaxis = [1 0 0];
Zaxis = [0 0 1];

parm.numViews = 4;

% enumerating unit vectors
gridSize = 3;
uVs = getUnitVectors(gridSize);
nuVs = size(uVs,1);
% enumerating angles
angles = linspace(-pi/24,pi/24,11);
numangles = length(angles);
IM = zeros(parm.sizeRoot*parm.sbin);
partInd = 0;
unitSquare = [0 0 1;1 0 1;1 1 0;0 1 1];
init_axis = unitSquare(:,1:end-1);
udata = [0 1];  vdata = [0 1];
%m 
for indY = 0 : parm.sizeRoot(1) - parm.sizeParts(1),
	for indX = 0 : parm.sizeRoot(2) - parm.sizeParts(2),
		partInd = partInd + 1;
		IM_p = IM;
		minX = 1+indX*parm.sbin;
		maxX = minX + parm.sizeParts(2)*parm.sbin - 1;
		minY = 1+indY*parm.sbin;
		maxY = minY + parm.sizeParts(1)*parm.sbin - 1;
		IM_p(minY:maxY,minX:maxX) = 1;
		if 0
			imshow(IM_p);
			pause;
			continue;
		end
		for uVid = 1:nuVs,
	        for angleid = 1:numangles,
	            rotationMAT = compute_rotation(uVs(uVid,:),angles(angleid));
				rotatedUnitSquare = unitSquare*rotationMAT;
				new_axis = rotatedUnitSquare(:,1:end-1);
				tform = maketform('projective',init_axis,new_axis);
				[B,xdata,ydata] = imtransform(IM_p, tform, 'bicubic', 'udata', udata, 'vdata', vdata, 'size', size(IM_p),'fill',0);
				
				continue;
	            v3 = v2*rotationMAT;
				% Image for Root Filter.
	    	    depths = v3(:,3);
				depths = depths - min(depths);
				%suffix = [
				if 0
				depths = depths - min(depths);
				depths = depths / max(depths);
				depths = 255*depths;
				depths = mat2gray(depths,[-20 255+20])*255;
				depths = 255 - depths;
	            depthcolor = [depths depths depths];
				end
				depths = 1.2*max(depths(:)) - depths;
				depthcolor = depths;
		        options.face_vertex_color = depthcolor;
				if partInd == 1,
					clf;
	    	        plot_mesh(v3,f,options);
    	    	    print('-dpng',sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
	        	    im = imread(sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
					im = removePadding_slim(im);
					im = rgb2gray(imresize(im,parm.sizeRoot*parm.sbin));
		            imwrite(im,sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
				end
				clf;
            	options.face_vertex_color(part_mask==1,:) = 0; %this part is Darkest.
            	%options.face_vertex_color(part_mask==0,:) = options.face_vertex_color(part_mask==0,:)*1.5; %making other parts lighter
	            plot_mesh(v3,f,options);
	            print('-dpng',sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
	            im = imread(sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
				im = removePadding_slim(im);
				im = rgb2gray(imresize(im,parm.sizeRoot*parm.sbin));
            	imwrite(im,sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
	        end %loop over angleid
    	end %loop over uVid
	end %loop over partX
end %loop over partY
