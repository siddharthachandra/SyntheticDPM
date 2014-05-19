%% preparation. getting fronto parallel.
addpath toolbox_graph
categories = {'monitortelevision'}%,'bed','chair','sofa','table'}
numC = length(categories);

parm.rootSize = [10 10];
parm.partSize = [3 3];
parm.widthX = 6;
parm.widthY = 6;
parm.widthZ = 6;

myfilter = fspecial('gaussian',[3 3], 2);
for cID = 1:numC,
	category = categories{cID};
	for insID = 1:1,
		if strcmp(category,'sofa'),
			ANG = 60;
		elseif strcmp(category,'monitortelevision'),
			ANG = 85;
		else,
			 ANG = 75;
		end
		if strcmp(category,'monitortelevision') && insID > 1,
			continue;
		end
		if strcmp(category,'bed') && insID == 3,
			continue;
		end
		element = [category num2str(insID)];
		clear y p r;
		load([element '.mat']);
		%% loading 3D model	
		v = load(fullfile('../3dModels/objs',[element '.obj.v']));
		f = load(fullfile('../3dModels/objs',[element '.obj.f']));
		%% fronto-parallel alignment
		R = angle2dcm(y,p,r);
		v = v*R; %vertices.
%		color_vertex = bsxfun(@minus,v,min(v));
%		color_vertex = bsxfun(@rdivide,color_vertex,max(color_vertex)); %between 0 and 1 NOW!
%		color_vertex = uint8(round(color_vertex*255));
%		minX = min(color_vertex(:,1));
%		maxX = max(color_vertex(:,1));
%		minY = min(color_vertex(:,2));
%		maxY = max(color_vertex(:,2));
%		minZ = min(color_vertex(:,3));
%		maxZ = max(color_vertex(:,3));
%		spaceX = linspace(double(minX),double(maxX),parm.widthX);
%		spaceY = linspace(double(minY),double(maxY),parm.widthY);
%		spaceZ = linspace(double(minZ),double(maxZ),parm.widthZ);
		spaceZ = linspace(0,255,parm.widthZ);
		spaceY = linspace(0,255,parm.widthY);
		spaceX = linspace(0,255,parm.widthX);
		%% getting PART identities
		% partIDs = gridQuantizeModel(v,parm.widthX,parm.widthY,parm.widthZ);
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
		angles = linspace(-pi/24,pi/24,11);
		numangles = length(angles);
		%% side-face
		for face = 1:3,
		    switch face
		        case 1 %front
		            angle = 0;
		        case 2 %rear
		            %angle = 180;
		            angle = ANG/2;
		        case 3 %profile1
		            angle = ANG;
		        case 4 %profile2
		            angle = -ANG/2;
				case 5
					angle = -ANG;
		    end
		    angle = angle*(pi/180);
		    %%  projecting to fronto parallel
		    Xaxis = [0 1 0];
		    rotationM = compute_rotation(Xaxis,angle);
		    v2 = v*rotationM;
		    %% projected
		    for uVid = 1:nuVs,
		        for angleid = 1:numangles,
		            rotationMAT = compute_rotation(uVs(uVid,:),angles(angleid));
		            v3 = v2*rotationMAT;
		            depths = v3(:,3);
					depths = 1.2 * max(depths(:)) - depths;
		            depthcolor = [depths depths depths];
		            options.face_vertex_color = depths; % mat2gray(depths);
					clf;
		            plot_mesh(v3,f,options);
		            print('-dpng',sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
		            im = imread(sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
					im = removePadding_slim(im);
					im = imresize(im,0.33);
		            imwrite(im,sprintf('parts_depths/depths/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
					clf;
					%depthcolor = color_vertex;
					depthcolor = v;
		            options.face_vertex_color = depthcolor; % mat2gray(depths);
		            plot_mesh_hires(v3,f,options);
		            print('-dpng',sprintf('parts_depths/parts/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
		            im = imread(sprintf('parts_depths/parts/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
					im = removePadding_slim(im);
					im = imresize(im,0.33);
		            imwrite(im,sprintf('parts_depths/parts/%s.f%d.u%d.a%d.png',element,face,uVid,angleid));
					newim = partifyImage(im,spaceX,spaceY,spaceZ);%keyboard;
					dlmwrite(sprintf('parts_depths/parts/%s.f%d.u%d.a%d.dat',element,face,uVid,angleid),newim,' ');
		        end
		    end
		end
	end
end
