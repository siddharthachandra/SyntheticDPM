%% preparation. getting fronto parallel.
addpath toolbox_graph
categories = {'monitortelevision','bed','chair','sofa','table'}
numC = length(categories);
myfilter = fspecial('gaussian',[3 3], 2);
for cID = 1:5, %numC,
	category = categories{cID};
	for insID = 1:4,
		if strcmp(category,'sofa'),
			ANG = 60;
		elseif strcmp(category,'monitortelevision'),
			ANG = 88;
		else,
			 ANG = 75;
		end
% 		if strcmp(category,'monitortelevision') && insID > 1,
% 			continue;
% 		end
		if strcmp(category,'bed') && insID == 3,
			continue;
		end
		element = [category num2str(insID)];
		clear y p r;
		load(['../3dModels/ypr/' element '.mat']);
		%% loading 3D model
		v = load(fullfile('../3dModels/objs',[element '.obj.v']));
		f = load(fullfile('../3dModels/objs',[element '.obj.f']));
		R = angle2dcm(y,p,r);
		v = v*R;
		
		%set(gcf, 'InvertHardcopy', 'off');
		%colordef black;
		%% prepared.
		set(0,'DefaultFigureColor',[1 1 1]);
		% enumerating unit vectors
		gridSize = 3;
		uVs = getUnitVectors(gridSize);
		nuVs = size(uVs,1);
		% enumerating angles
		%angles = linspace(0,pi/12,10);
		angles = linspace(-pi/24,pi/24,10);
		numangles = length(angles);
		%% side-face
		for face = 1:4,
		    switch face
		        case 1 %front
		            angle = 0;
		        case 2 %rear
					angle = 180;
				case 3
		            %angle = 180;
		            angle = ANG/2;
		        case 4 %profile1
		            angle = ANG;
		        case 5 %profile2
		            angle = -ANG/2;
				case 6
					angle = -ANG;
		    end
		    angle = angle*(pi/180);
		    %%  projecting to face
		    Xaxis = [0 1 0];
		    rotationM = compute_rotation(Xaxis,angle);
		    v2 = v*rotationM;
		    %plot_mesh(v2,f,options);
			%return;
		    %% projected
		    for uVid = 1:nuVs,
		        for angleid = 1:numangles,
		            rotationMAT = compute_rotation(uVs(uVid,:),angles(angleid));
		            v3 = v2*rotationMAT;
		            depths = v3(:,3);
					depths = 1.2 * max(depths(:)) - depths;
		            depthcolor = [depths depths depths];
		            options.face_vertex_color = depths; % mat2gray(depths);
		            plot_mesh(v3,f,options);
%                     keyboard;
		            print('-dpng',sprintf('../../NIPS_DATA/%s/%s.f%d.u%d.a%d.png',category,element,face,uVid,angleid));
		            im = imread(sprintf('../../NIPS_DATA/%s/%s.f%d.u%d.a%d.png',category,element,face,uVid,angleid));
					im = removePadding_slim(im);
					im = imresize(im,[8 8]*8);
					%myfilteredimage = imfilter(im, myfilter, 'replicate');
		            imwrite(im,sprintf('../../NIPS_DATA/%s/%s.f%d.u%d.a%d.png',category,element,face,uVid,angleid));
					clf;
		        end
		    end
		end
	end
end
