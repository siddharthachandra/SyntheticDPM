function genParts(list),
diary([list '.' date '-' datestr(now, 'HH:MM:SS') '.log']);
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
parm.useBinary = 0;
parm.sanityChecks = 1;
parm.PART_INDICATORS_DIR = 'parts_depths/parts/';
parm.DEPTH_DIR = 'parts_depths/depths';
parm.tolerance = {0.25,0.25,0.08};
parm.partLength = prod([parm.sizeParts parm.featDim]) + 4; %dy,dx,dy^2,dx^2
parm.rootLength = prod([parm.sizeRoot parm.featDim]);

parm.numParts = parm.widthZ*parm.widthY*parm.widthX; %prod(parm.sizeRoot - parm.sizeParts + 1);
partTemplate = ones(parm.sizeParts*parm.sbin);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GENERATING INDICATORS. deactivating parts which aren't present.
load coverage.mat %% this was pre-measured. contains the coverage of parts.
parm.partIndicators = {};
for view = 1 : parm.numViews,
	useful_parts = max(coverage) > parm.tolerance{view}*sum(partTemplate(:)); 
	useful_parts(end) = 0; %this is the white pixel (Background)
	parm.partIndicators{view} = double(useful_parts);
	parm.usefulParts{view} = useful_parts;
	parm.visibleParts{view} = zeros(size(useful_parts));
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
parm
for sample = 1 : parm.numSamples,
	[pat fil ext] = fileparts(lines{sample});
	
	depth_im = imread(fullfile(parm.DEPTH_DIR,[fil '.png']));
	part_im = load(fullfile(parm.PART_INDICATORS_DIR,[fil '.dat']));
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
				parm.visibleParts{y.viewPoint}(part) = 1;
				yp = YY(xp);
				yp = min(max(1,round(yp/parm.sbin)),parm.sizeRoot(1)-parm.sizeParts(1)+1);
				xp = min(max(1,round(xp/parm.sbin)),parm.sizeRoot(2)-parm.sizeParts(2)+1);
				y.parts{part} = [yp xp [yp xp]+(parm.sizeParts -1) 1 ]; %this part is absent
			else
				y.parts{part} = [-1 -1 -1 -1 0]; %this part is absent
			end
		else
			y.parts{part} = [-1 -1 -1 -1 0]; %this part is absent
		end
	end
	Y{sample} = y;
end
sizeFeat = parm.numViews*( prod([parm.sizeRoot parm.featDim]) + parm.numParts * (4 + prod([parm.sizeParts parm.featDim])));
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
%global maxScore;

lpparm = struct; %linear programming parameters.
lpparm.A = zeros(1,parm.numParts);
lpparm.Aeq = ones(1,parm.numParts);
lpparm.b = 0;
lpparm.beq = 8;
lpparm.lb = zeros(parm.numParts,1);
lpparm.ub = ones(parm.numParts,1);
parm.c = 100;
parm.e = 0.001;
while doNotBreak,
	iter = iter + 1;
	fprintf('Bi Convex Optimization iteration %d\n',iter);
	model = svm_struct_learn(sprintf('-c %f -e %f -v 3 ',parm.c,parm.e), parm);
	avgLoss = getPredictionLoss(parm,model);
	fprintf('Average Prediction Loss per Sample: %g\n',avgLoss);
	%keyboard;
	%% Update Part Indicators HERE.
	parms = parm;
	parm = cutting_plane_solve_p(parm,model);
	avgLoss = getPredictionLoss(parm,model);
	fprintf('Average Prediction Loss per Sample: %g\n',avgLoss);
	obj = get_objective_val(parm,model);
	fprintf('=================================\n');
	fprintf('Iteration %d. Objective Value: %g\n',iter,obj);
	fprintf('=================================\n');
	changes = cell2mat(parms.partIndicators) - cell2mat(parm.partIndicators);
	changes = sum(changes);	
	if changes == 0,
		doNotBreak = 0;
	end
	parms = parm;
	parm = rmfield(parms,'patterns');
	parm = rmfield(parms,'labels');
	save([list sprintf('.C%d.%04d',parm.c,iter) '.mat'],'parm','model','-v7.3');
	parm = parms;
	clear parms;
end
diary off;
end


function obj = get_objective_val(parm,model)
	obj = 0;
	for sample = 1 : parm.numSamples,
		[ywhat, maxScore, rootScore, partScore] = mvc(parm,model,parm.patterns{sample},parm.labels{sample});
		[gt_rootScore,gt_partScores,gt_totalScore] = gt_score(parm,model.w,parm.patterns{sample},parm.labels{sample});
		obj = obj + maxScore - gt_totalScore;
	end
	obj = (parm.c/parm.numSamples)*obj;
	obj = obj + 0.5 * model.w' * model.w;
end

function [avgLoss] = getPredictionLoss(parm,model),
	avgLoss = 0;
	fprintf('Losses: ');
	for sample = 1 : parm.numSamples,
		yhat = predict(parm,model,parm.patterns{sample});
		sampleLoss = loss(parm,parm.labels{sample},yhat);
		fprintf('%g ',sampleLoss);
		avgLoss = avgLoss + sampleLoss;
	end
	fprintf('\n');
	avgLoss = avgLoss / parm.numSamples;
end
