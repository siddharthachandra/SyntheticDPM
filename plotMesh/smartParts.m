%% preparation. getting fronto parallel.
addpath toolbox_graph
%categories = {'monitortelevision'}%,'bed','chair','sofa','table'}
categories = {'bed','chair','sofa','table'}
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


%%%

IM = zeros(parm.sizeRoot*parm.sbin);
partInd = 0;
unitSquare = [0 0 1;1 0 1;1 1 0;0 1 1];
%unitSquare = [0 0 1;0 1 1;1 1 0;1 0 1];
init_axis = unitSquare(:,1:end-1);
vdata = [0 1];  udata = [0 1];
vertex_suffix = [ -20 -20 -inf; -20 100 -inf; 100 100 -inf; 100 -20 inf];
%%%
for cID = 1:numC,
	category = categories{cID};
	for insID = 1:1, %number of instances (3D models)
		if strcmp(category,'sofa'),
			ANG = 60;
		elseif strcmp(category,'monitortelevision'),
			ANG = 85;
		else,
			 ANG = 75;
		end

		if strcmp(category,'monitortelevision') && insID > 1, %we have only one 3D model for monitors.
			continue;
		end

		if strcmp(category,'bed') && insID == 3, %we have only three 3D models for beds.
			continue;
		end

		element = [category num2str(insID)];

		clear y p r;
		%% loading 3D model	

		load([element '.mat']);

		v = load(fullfile('../3dModels/objs',[element '.obj.v']));
		f = load(fullfile('../3dModels/objs',[element '.obj.f']));
		%% fronto-parallel alignment
		R = angle2dcm(y,p,r);
		v = v*R; %vertices aligned to the fronto parallel view.

		%% resizing the model to fit the parm size.
		minX = min(v(:,find(Xaxis)));
		maxX = max(v(:,find(Xaxis)));
		sizeX = maxX - minX;
		minY = min(v(:,find(Yaxis)));
		maxY = max(v(:,find(Yaxis)));
		sizeY = maxY - minY;
		minZ = min(v(:,find(Zaxis)));
		maxZ = max(v(:,find(Zaxis)));
		sizeZ = maxZ - minZ;
		imDim = (parm.sizeRoot(1))*parm.sbin; %add two padded hog cells.
		scaleX = imDim / sizeX;
		scaleY = imDim / sizeY;
		scaleZ = imDim / sizeZ;
		v(:,find(Xaxis)) = v(:,find(Xaxis)) * scaleX;
		v(:,find(Yaxis)) = v(:,find(Yaxis)) * scaleY;
		v(:,find(Zaxis)) = v(:,find(Zaxis)) * scaleZ;
		
		%% Pre-Process-And-Keep Basis Views.
		vertex_Face = cell(1,parm.numViews);
		for face = 1 : parm.numViews,
		    switch face
		        case 1 %front
		            angle = 0;
		        case 2 %rear
		            angle = 180;
		        case 3 %profile1
		            angle = ANG;
		        case 4 %profile2
		            angle = ANG/2;
		    end
		    angle = angle*(pi/180);
		    %%  projecting to the desired viewPoint 
		    rotationM = compute_rotation(Xaxis,angle);
			v_face = v*rotationM;
			minX = min(v_face(:,find(Xaxis)));
			minY = min(v_face(:,find(Yaxis)));
			v_face(:,find(Xaxis)) = v_face(:,find(Xaxis)) - minX;
			v_face(:,find(Yaxis)) = v_face(:,find(Yaxis)) - minY;
		    vertex_Face{face} = v_face;
		    %% projected
		end		

		set(0,'DefaultFigureColor',[1 1 1]);

		%% Draw each Part.
		partInd = 0;	
		for indY = 0 : parm.sizeRoot(1) - parm.sizeParts(1),
			for indX = 0 : parm.sizeRoot(2) - parm.sizeParts(2),
				%%%
				if 0
					IM_p = IM;
		        	minX = 1+indX*parm.sbin;
        			maxX = minX + parm.sizeParts(2)*parm.sbin - 1;
			        minY = 1+indY*parm.sbin;
    	    		maxY = minY + parm.sizeParts(1)*parm.sbin - 1;
			        IM_p(minY:maxY,minX:maxX) = 1;
				end
				%%%
				partInd = partInd + 1;
				for face = 1 : parm.numViews,
					v2 = vertex_Face{face};
					v2_augmented = v2;	
					f2_augmented = f;
					%resetting minX,maxX and so on.
					maxZ = max(v2(:,find(Zaxis)));
					minX = indX*parm.sbin;
					maxX = minX + (parm.sizeParts(2))*parm.sbin;
					minY = indY*parm.sbin;
					maxY = minY + (parm.sizeParts(1))*parm.sbin;
					[minX maxX minY maxY]
					[min(v2(:,find(Xaxis))) max(v2(:,find(Xaxis))) min(v2(:,find(Yaxis))) max(v2(:,find(Yaxis)))]
					if 1
						suffix = [ minY minX maxZ+1; minY maxX maxZ+1; maxY maxX maxZ+1; maxY minX maxZ+1];
						numV = size(v2,1);
						faces_suffix = [numV+1 numV+2 numV+3; numV+1 numV+3 numV+4];
						v2_augmented = [v2_augmented; suffix];
						f2_augmented = [f2_augmented ;faces_suffix];
						part_mask = zeros(size(v2_augmented,1),1);
						v2_match_x = (v2_augmented(:,find(Xaxis)) >= minX - small) & (v2_augmented(:,find(Xaxis)) <= maxX + small);
						v2_match_y = (v2_augmented(:,find(Yaxis)) >= minY - small) & (v2_augmented(:,find(Yaxis)) <= maxY + small);
						part_mask(v2_match_y & v2_match_x) = 1; %brought to the camera. 
					end
					if 0, %check the parts..
						options.face_vertex_color = v2(:,find(Zaxis));
						clf;
						%subplot(2,1,1);plot_mesh(v2,f,options);
						figure(1);plot_mesh(v2,f,options);
						options.face_vertex_color(find(part_mask)) = 0;
						%options.face_vertex_color(find(part_mask==0)) = 100;
						%subplot(2,1,2);plot_mesh(v2_augmented,f2_augmented,options);
						figure(2);plot_mesh(v2_augmented,f2_augmented,options);
						pause;
						continue;
					end
					%%%% we can insert 4 vertices to mark the territory. Let's do that.
					%suffix = [minX minY 0;
					for uVid = 1:nuVs,
				        for angleid = 1:numangles,
				            rotationMAT = compute_rotation(uVs(uVid,:),angles(angleid));
							
							%%%
							if 0
								rotatedUnitSquare = unitSquare*rotationMAT;
    		            		new_axis = [rotatedUnitSquare(:,2) rotatedUnitSquare(:,1)];
        			        	tform = maketform('projective',init_axis,new_axis);
				                [B,xdata,ydata] = imtransform(IM_p, tform, 'bicubic', 'udata', udata, 'vdata', vdata, 'size', size(IM_p),'fill',0);
							end
							%%%

				            v3 = v2*rotationMAT;
							v3_augmented = v2_augmented*rotationMAT;
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
							if 0,
								depthcolor = [depthcolor; 0; 0; 0; 0];
								depthcolor(part_mask > 0.5) = 0; 
							end
							depthcolor(part_mask(1:end-4)>0.5) = 0;
			            	options.face_vertex_color = depthcolor; %this part is Darkest.
				            %plot_mesh(v3_augmented,f2_augmented,options);
				            plot_mesh(v3,f,options);
				            print('-dpng',sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
				            im = imread(sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
							im = removePadding_slim(im);
							im = rgb2gray(imresize(im,parm.sizeRoot*parm.sbin));
			            	imwrite(im,sprintf('parts_depths/parts/%s.f%d.u%d.a%d.p%d.png',element,face,uVid,angleid,partInd));
							if 0,
								subplot(2,2,1);plot_mesh(v2,f,options);
								subplot(2,2,2); imshow(IM_p);
								subplot(2,2,3);plot_mesh(v3,f,options);
								subplot(2,2,4); imshow(B);
								pause;
							end
				        end %loop over angleid
		    		end %loop over uVid
				end %loop over faces
			end %loop over partX
		end %loop over partY
	end %loop over Instances
end %loop over category
