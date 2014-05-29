function genParts(list),
parm.allowedParts = 8;
parm.sizeParts = [3 3];
parm.sizeRoot = [10 10];
parm.numViews = 5;
parm.featDim = 32;
parm.numParts = prod(parm.sizeRoot - parm.sizeParts + 1);
X = {};
Y = {};
%% prepare Data
lines = textread(list,'%s');
parm.numSamples = length(lines);
fprintf('NUMLINES READ: %d\n',parm.numSamples);
numSamplesPerView = parm.numSamples / parm.numViews;
%dbstop if error;
for sample = 1 : parm.numSamples,
	im = imread(lines{sample});
	im = imresize(im,(parm.sizeRoot+2)*8);
	hog = features(double(im),8);
	X{sample} = hog;
	y.viewPoint = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	part = 0;
	for x = 1 : parm.sizeRoot(2) - parm.sizeParts(2) + 1,
		for yy = 1 : parm.sizeRoot(1) - parm.sizeParts(1) + 1,
		part = part + 1;
		yx = [yy x];
		y.parts{part} = [yx yx+(parm.sizeParts - 1)];
		end
	end
	assert(part == parm.numParts);
	Y{sample} = y;
end
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
parm.constraintFn = @predict;
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
end
indicators = parm.partIndicators;
save([list '.mat'],'indicators','model','-v7.3');
end
