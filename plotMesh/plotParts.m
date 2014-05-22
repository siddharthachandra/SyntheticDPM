%% preparation. getting fronto parallel.
addpath toolbox_graph
%categories = {'monitortelevision'}%,'bed','chair','sofa','table'}
categories = {'bed','chair','sofa','table','monitortelevision'}
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
cropBOX = struct;
parm.numViews = 4;

% enumerating unit vectors
gridSize = 3;
uVs = getUnitVectors(gridSize);
nuVs = size(uVs,1);
% enumerating angles
angles = linspace(-pi/24,pi/24,5);
numangles = length(angles);


for cID = 1:numC,
	category = categories{cID};
	for insID = 1:1, %number of instances (3D models)
%         keyboard;
		if strcmp(category,'sofa'),
			ANG = 60;
		elseif strcmp(category,'monitortelevision'),
			ANG = 88;
		else,
			 ANG = 75;
		end

		if insID>4 && strcmp(category,'monitortelevision') == 0, %we have only one 3D model for monitors.
			continue;
		end

		if strcmp(category,'bed') && insID == 3, %we have only three 3D models for beds.
			continue;
		end

		element = [category num2str(insID)];

		partInd = 0;	
		for indY = 0 : parm.sizeRoot(1) - parm.sizeParts(1),
			for indX = 0 : parm.sizeRoot(2) - parm.sizeParts(2),
				partInd = partInd + 1;
				for face = 1 : 1, %parm.numViews,
					for uVid = 1:nuVs,
				        for angleid = 1:numangles,
							clf;
				        	baseIM = imread(sprintf('../../NIPS_DATA/parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
							%baseIM = baseIM(:,:,1);
				            mask = imread(sprintf('../../NIPS_DATA/parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
							mask = mask > 100;
							baseIM = baseIM.*uint8(cat(3,mask,mask,mask));
% 							keyboard;
							baseIM = baseIM + uint8(cat(3,zeros(size(mask)),200*(1-mask),zeros(size(mask))));
							
							imshow(baseIM);
% 							keyboard;
							[x y X Y] = bboxFromMask(mask);
							bbox = [y x Y X];
							imshow(baseIM);
							c = 'g'; %green
							cwidth = 2.4; %width of line
							s = '-'; %line style
							line([bbox(1) bbox(1) bbox(3) bbox(3) bbox(1)]', [bbox(2) bbox(4) bbox(4) bbox(2) bbox(2)]', 'color', c, 'linewidth', cwidth, 'linestyle', s);
							print('-dpng',sprintf('../../NIPS_DATA/plotParts/%d/%s.f%d.u%d.a%d.png',partInd,element,face,uVid,angleid));
				        end %loop over angleid
		    		end %loop over uVid
				end %loop over faces
                return;
			end %loop over partX
		end %loop over partY
	end %loop over Instances
end %loop over category
