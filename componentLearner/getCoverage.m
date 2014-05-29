function genParts(list),
list = 'sanity.list';
list = 'mn.list2'
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

parm.numParts = parm.widthZ*parm.widthY*parm.widthX; %prod(parm.sizeRoot - parm.sizeParts + 1);

X = {};
Y = {};
%% prepare Data
lines = textread(list,'%s');
parm.numSamples = length(lines);
fprintf('NUMLINES READ: %d\n',parm.numSamples);
numSamplesPerView = parm.numSamples / parm.numViews;
partTemplate = ones(parm.sizeParts*parm.sbin);
%dbstop if error;
coverage = zeros(parm.numSamples,parm.numParts);
for sample = 1 : parm.numSamples,
	[pat fil ext] = fileparts(lines{sample});
	
	part_im = load(fullfile(PART_INDICATORS_DIR,[fil '.dat']));
	if 0
	depth_im = imread(fullfile(DEPTH_DIR,[fil '.png']));
	depth_im = imresize(depth_im,size(part_im));
	im = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
	hog = features(double(im),parm.sbin);
	X{sample} = hog;
	y.viewPoint = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	part = 0;
	scl = ((parm.sizeRoot+2)*parm.sbin)./size(part_im);
	numPartsUsedSoFar = 0;
	end
	maxCover = -Inf;
	meanCover = 0;
	for part = 1 : parm.numParts,
		if any(part_im(:) == part),
			score = conv2(double(part_im == part), partTemplate, 'valid');
			[v, YY] = max(score);
			[v, xp] = max(v);
			coverage(sample,part) = v;
			if 0
			yp = YY(xp);
			xx = xp; yy=yp;
			%% changing 
			yp = min(max(1,round(scl(1)*yp/parm.sbin)),parm.sizeRoot(1)-parm.sizeParts(1)+1);
			xp = min(max(1,round(scl(2)*xp/parm.sbin)),parm.sizeRoot(2)-parm.sizeParts(2)+1);
			y.parts{part} = [yp xp [yp xp]+(parm.sizeParts -1) ]; %this part is absent
			end
		else
			y.parts{part} = [-1 -1 -1 -1]; %this part is absent
		end
	end
	if 0
	Y{sample} = y;
	end
	save coverage.mat coverage
end
return;
parm.partIndicators = {};
for view = 1 : parm.numViews,
	parm.partIndicators{view} = ones(1,parm.numParts);
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
