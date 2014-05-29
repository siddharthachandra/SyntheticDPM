function genParts(list),

dbstop if error;
parm.allowedParts = 8;
parm.sizeParts = [3 3];
parm.sizeRoot = [10 10];
parm.numViews = 3;
parm.featDim = 32;
parm.widthX = 6;
parm.widthY = 6;
parm.widthZ = 6;
parm.sbin = 8;
PART_INDICATORS_DIR = 'parts_depths/parts/'
DEPTH_DIR = 'parts_depths/depths'
parm.tolerance = {0.25,0.25,0.08};

parm.numParts = parm.widthZ*parm.widthY*parm.widthX; %prod(parm.sizeRoot - parm.sizeParts + 1);
partTemplate = ones(parm.sizeParts*parm.sbin);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GENERATING INDICATORS. deactivating parts which aren't present.
load coverage.mat %% this was pre-measured. contains the coverage of parts.
parm.partIndicators = {};
for view = 1 : parm.numViews,
	useful_parts = max(coverage) > parm.tolerance{view}*sum(partTemplate(:)); 
	useful_parts(end) = 0; %this is the white pixel (Background)
	parm.partIndicators{view} = useful_parts; 
	fprintf('View %d has %d Useful Parts\n',view,sum(useful_parts));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = {};
Y = {};
%% prepare Data
lines = textread(list,'%s');
parm.numSamples = length(lines);
fprintf('NUMLINES READ: %d\n',parm.numSamples);
numSamplesPerView = parm.numSamples / parm.numViews;
%dbstop if error;
for sample = 1 : parm.numSamples,
	[pat fil ext] = fileparts(lines{sample});
	
	depth_im = imread(fullfile(DEPTH_DIR,[fil '.png']));
	part_im = load(fullfile(PART_INDICATORS_DIR,[fil '.dat']));
	depth_im = imresize(depth_im,size(part_im)); %%depth and part images are the same size now.
	depth_im = padarray(depth_im,[3 3]*parm.sbin,255); %% adding 3 strips of hog cells.
	part_im  = padarray(part_im, [3 3]*parm.sbin,0); %%adding 3 strips of black.
	im       = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
	part_im  = imresize(part_im, (parm.sizeRoot+2)*parm.sbin,'nearest');
	hog = features(double(im),parm.sbin);
	X{sample} = hog;
	y.viewPoint = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	for part = 1 : parm.numParts,
		if parm.partIndicators{y.viewPoint}(part) && any(part_im(:) == part),
            score = conv2(single(part_im == part), partTemplate, 'valid');
			[v,YY] = max(score);
			[v,xp] = max(v);
			if v>parm.tolerance{y.viewPoint}*sum(partTemplate(:)),%this part is present
				yp = YY(xp);
				yp = min(max(1,round(yp/parm.sbin)),parm.sizeRoot(1)-parm.sizeParts(1)+1);
				xp = min(max(1,round(xp/parm.sbin)),parm.sizeRoot(2)-parm.sizeParts(2)+1);
				y.parts{part} = [yp xp [yp xp]+(parm.sizeParts -1) ]; %this part is absent
			else
				y.parts{part} = [-1 -1 -1 -1]; %this part is absent
			end
		else
			y.parts{part} = [-1 -1 -1 -1]; %this part is absent
		end
	end
	Y{sample} = y;
end
sizeFeat = parm.numViews*( prod([parm.sizeRoot parm.featDim]) + parm.numParts * prod([parm.sizeParts parm.featDim]));
%% let's learn some SVMs
parm.patterns = X;
parm.labels = Y;
parm.lossFn = @loss;
parm.featureFn = @mypsi;
parm.constraintFn = @mvc;
parm.dimension = sizeFeat;
%%% bi - convex. Learn Model. Update Part Indicators. Repeat.
doNotBreak = 1;
iter = 0;
while doNotBreak,
	iter = iter + 1;
	fprintf('Bi Convex Optimization iteration %d\n',iter);
	model = svm_struct_learn('-c 100 -e 0.001 -v 3 ', parm);
	%% Update Part Indicators HERE.
	tempparm = parm;
	changes = 0;
	for view = 1 : parm.numViews, %each view has a different set of part Indicators.
		scoreArray = zeros(parm.numParts,1);
		for part = 1 : parm.numParts, %compute score for each part over samples.
			score = 0;
			tempparm.partIndicators{view} = zeros(1,parm.numParts);
			tempparm.partIndicators{view}(part) = 1; 
			for sample = 1 : parm.numSamples,
				if parm.labels{sample}.viewPoint ~= view,
					continue; %ignore irrelevant samples.
				end
				score = score + dot(model.w,mypsi(tempparm,tempparm.patterns{sample},tempparm.labels{sample}));
			end
			scoreArray(part) = score;
		end
		%fprintf('view %d SCORES: %s\n',view,num2str(scoreArray));
		[val pos] = sort(scoreArray,'descend');
		tempparm.partIndicators{view} = zeros(1,parm.numParts);
		tempparm.partIndicators{view}(pos(1:parm.allowedParts)) = 1;
		changes = changes + sum(abs(tempparm.partIndicators{view} - parm.partIndicators{view}));
	end
	parm = tempparm;
	if changes == 0,
		doNotBreak = 0;
	end
	parms = parm;
	parms = rmfield(parms,'patterns');
	parms = rmfield(parms,'labels');
	save([list sprintf('.%04d',iter) '.mat'],'parm','model','-v7.3');
end
end
