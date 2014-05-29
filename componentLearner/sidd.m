parm.numParts = 10;
parm.allowedParts = 4;
parm.sizeParts = [6 6];
parm.sizeRoot = [10 10];
parm.numSamples = 12;
parm.numViews = 4;
parm.featDim = 32;
X = {};
Y = {};
%% prepare Data
for sample = 1 : parm.numSamples,
	X{sample} = rand([parm.sizeRoot parm.featDim]);
	y.viewPoint = rem(sample,parm.numViews);
	if y.viewPoint == 0,
		y.viewPoint = parm.numViews;
	end	
	for part = 1 : parm.numParts,
		yx = round(rand(1,2).*(parm.sizeRoot - parm.sizeParts)) + 1;
		y.parts{part} = [yx yx+(parm.sizeParts - 1)];
	end
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
		fprintf('view %d SCORES: %s\n',view,num2str(scoreArray));
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
