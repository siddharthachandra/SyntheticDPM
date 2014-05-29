function genParts(s_list,r_list,varargin),

parm = struct;

diary([list '.' date '-' datestr(now, 'HH:MM:SS') '.log']);

for i = 1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    eval(['parm.' key ' = val;']);
end

parm.fct = 0.2;

if ~isfield(parm,'useDisp'),
    parm.useDisp = 1;
end

if ~isfield(parm,'numComps'),
    parm.numComps = 3;
end

if ~isfield(parm,'sizeRoot'),
    parm.sizeRoot = [10 10]; % 8x8 bbox, 2 hog cell padding (4x4), 12x12 repn, after hog becomes 10x10.
end

parm.sizeDisp = 16;
parm.featDim = 32;

if parm.useDisp,
    parm.featDim = parm.featDim + parm.sizeDisp;
end

if ~isfield(parm,'sbin'),
    parm.sbin = 8;
end

if ~isfield(parm,'padHog'),
    parm.padHog = 0;
end

if ~isfield(parm,'sanityChecks'),
    parm.sanityChecks = 1;
end

parm.rootLength = prod([parm.sizeRoot parm.featDim]);
parm.sizeBBOX = parm.sizeRoot + 2*parm.padHog - 2;

if ~isfield(parm,'c1'),
    parm.c1 = 1;
end

if ~isfield(parm,'c2'),
    parm.c2 = 1;
end

if ~isfield(parm,'alpha'),
	parm.alpha = 1;
end

if ~isfield(parm,'e'),
    parm.e = 0.001;
end


X = {};
Y = {};

parm.N1 = 0;
parm.N2 = 0;

addpath ../plotMesh
%% prepare Synthetic Data.

lines = textread(s_list,'%s');
numLines = length(lines);
fprintf('Reading Synthetic Examples (%s). Read %d lines.\n',s_list,numLines);

maxFace = Inf;
if isfield(parm,'faceMax'),
    maxFace = parm.faceMax;
end

for sample = 1 : numLines,
    v_init = findstr(lines{sample},'.f');
    v_end  = findstr(lines{sample},'.u');
    viewPoint = eval(lines{sample}(v_init+2:v_end-1));
    if viewPoint > maxFace,
        continue;
    end
    parm.N1 = parm.N1 + 1;

    [pat fil ext] = fileparts(lines{sample});
    depth_im = imread(fullfile(pat,[fil ext]));
    depth_im = cleanImage(depth_im);
    [im t b l r] = removePadding_slim_thresh(depth_im,200);
    im = imresize(im,(parm.sizeRoot+2)*parm.sbin);
    hog = features(double(cat(3,im,im,im)),parm.sbin);
    if parm.useDisp,
        dispF = getDispFeatures(imresize(im,parm.sizeRoot*parm.sbin),parm.sbin);
        X{sample} = cat(3,hog,dispF);
    else
        X{sample} = hog;
    end
	
    y.viewPoint = viewPoint;
	y.component = zeros(parm.numComps,1);
    Y{sample} = y;
end

%% prepare Real Data.

lines = textread(r_list,'%s');
numLines = length(lines);
fprintf('Reading Real Examples (%s). Read %d lines.\n',s_list,numLines);

maxFace = Inf;
if isfield(parm,'faceMax'),
    maxFace = parm.faceMax;
end

for sample = 1 : numLines,
    parm.N2 = parm.N2 + 1;

    [pat fil ext] = fileparts(lines{sample});
    depth_im = imread(fullfile(pat,[fil ext]));
	depth_im = depth_im(:,:,end);
    im = imresize(im,(parm.sizeRoot+2)*parm.sbin);
    hog = features(double(cat(3,im,im,im)),parm.sbin);
    if parm.useDisp,
        dispF = getDispFeatures(imresize(im,parm.sizeRoot*parm.sbin),parm.sbin);
        X{parm.N1+sample} = cat(3,hog,dispF);
    else
        X{parm.N1+sample} = hog;
    end
    y.viewPoint = -1;
	y.component = zeros(parm.numComps,1);
    Y{parm.N1+sample} = y;
end

parm.dimension = parm.numComps*prod([parm.sizeRoot parm.featDim]);
keyboard;
%% Initialize components for the Synthetic Examples.
for sample = 1 : parm.N1,
	v = Y{sample}.viewPoint;
	if v<=9,
		Y{parm.N1+sample}.component(1) = 1;
	elseif v<=15,
		Y{parm.N1+sample}.component(2) = 1;
	else
		Y{parm.N1+sample}.component(3) = 1;
	end
end

parm.N = parm.N1 + parm.N2;

%% Learn component Classifier from Synthetic Data Only.
parm.patterns = X{1:parm.N1};
parm.labels = Y{1:parm.N1};
parm.lossFn = @loss_c;
parm.featureFn = @mypsi_c;
parm.constraintFn = @mvc_c;

model = svm_struct_learn(sprintf('-c %f -e %f -v 3 ',parm.c1,parm.e), parm);

%% Initialize components for Real Examples.
for sample = parm.N1 : parm.N1 + parm.N2,
	Y{sample} = predict_c(parm,model,X{sample},Y{sample});
end

%% Add Real Examples to Train Set.
parm.patterns = X;
parm.labels = Y;

%%% bi - convex. Learn Model. Update Components. Repeat.
doNotBreak = 1;
iter = 0;

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
