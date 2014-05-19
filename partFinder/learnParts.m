function genParts(list,varargin),

parm = struct;

for i = 1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    eval(['parm.' key ' = val;']);
end

diary([list '.pF.' date '-' datestr(now, 'HH:MM:SS') '.log']);
dbstop if error;

if ~isfield(parm,'sizeRoot'),
    parm.sizeRoot = [10 10];
end

parm.featDim = 32;

if ~isfield(parm,'sizeParts'),
    parm.sizeParts = [3 3];
end

parm.fct = 0.2;

if ~isfield(parm,'allowedParts'),
    parm.allowedParts = 8;
end

parm.numViews = 1;

if ~isfield(parm,'sbin'),
    parm.sbin = 8;
end

if ~isfield(parm,'sanityChecks'),
    parm.sanityChecks = 1;
end

parm.useBinary = 0;

if ~isfield(parm,'c'),
    parm.c = 100;
end

if ~isfield(parm,'e'),
    parm.e = 0.001;
end

if ~isfield(parm,'view'),
	parm.view = 1;
end

parm.PART_INDICATORS_DIR = 'parts_depths/parts/';
parm.DEPTH_DIR = 'parts_depths/depths';

parm.tolerance = {0.25,0.25,0.08};

parm.partLength = prod([parm.sizeParts parm.featDim]) + 4; %dy,dx,dy^2,dx^2
parm.rootLength = prod([parm.sizeRoot parm.featDim]);

if ~isfield(parm,'numParts'),
	parm.numParts = 216; %prod(parm.sizeRoot - parm.sizeParts + 1);
end

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
numSamples = length(lines);
fprintf('NUMLINES READ: %d\n',numSamples);
parm.numSamples = 0;
%dbstop if error;
for sample = 1 : numSamples,
	[pat fil ext] = fileparts(lines{sample});
	y.viewPoint = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	if y.viewPoint ~= parm.view,
		continue;
	end
	parm.numSamples = parm.numSamples + 1;
	depth_im = imread(fullfile(parm.DEPTH_DIR,[fil '.png']));
	part_im = load(fullfile(parm.PART_INDICATORS_DIR,[fil '.dat']));
	depth_im = imresize(depth_im,size(part_im)); %%depth and part images are the same size now.
	depth_im = padarray(depth_im,[3 3]*parm.sbin,255); %% adding 3 strips of hog cells.
	part_im  = padarray(part_im, [3 3]*parm.sbin,0); %%adding 3 strips of black.
	im       = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
	part_im  = imresize(part_im, (parm.sizeRoot+2)*parm.sbin,'nearest');
	hog = features(double(im),parm.sbin);
	X{parm.numSamples} = hog;
	for part = 1 : parm.numParts,
		if parm.partIndicators{1}(part) && any(part_im(:) == part),
            score = conv2(single(part_im == part), partTemplate, 'valid');
			[v,YY] = max(score);
			[v,xp] = max(v);
			if v>parm.tolerance{1}*sum(partTemplate(:)),%this part is present
				parm.visibleParts{1}(part) = 1;
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
	Y{parm.numSamples} = y;
end
parm.dimension = parm.numParts * (4 + prod([parm.sizeParts parm.featDim]));
%% let's learn some SVMs
parm.patterns = X;
parm.labels = Y;
parm.lossFn = @loss_pf;
parm.featureFn = @mypsi_pf;
parm.constraintFn = @mvc_pf;
%%% bi - convex. Learn Model. Update Part Indicators. Repeat.
doNotBreak = 1;
iter = 0;
parm
while doNotBreak,
	iter = iter + 1;
	fprintf('Bi Convex Optimization iteration %d\n',iter);
	model = svm_struct_learn(sprintf('-c %f -e %f -v 3 ',parm.c,parm.e), parm);
	avgLoss = getPredictionLoss(parm,model);
	fprintf('Average Prediction Loss per Sample: %g\n',avgLoss);
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
		[ywhat, maxScore, partScore] = parm.constraintFn(parm,model,parm.patterns{sample},parm.labels{sample});
		[gt_partScores,gt_totalScore] = gt_score_pf(parm,model.w,parm.patterns{sample},parm.labels{sample});
		obj = obj + maxScore - gt_totalScore;
	end
	obj = (parm.c/parm.numSamples)*obj;
	obj = obj + 0.5 * model.w' * model.w;
end

function [avgLoss] = getPredictionLoss(parm,model),
	avgLoss = 0;
	fprintf('Losses: ');
	for sample = 1 : parm.numSamples,
		yhat = predict_pf(parm,model,parm.patterns{sample});
		sampleLoss = loss_pf(parm,parm.labels{sample},yhat);
		fprintf('%g ',sampleLoss);
		avgLoss = avgLoss + sampleLoss;
	end
	fprintf('\n');
	avgLoss = avgLoss / parm.numSamples;
end
