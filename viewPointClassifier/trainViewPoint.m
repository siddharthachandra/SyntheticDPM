function trainViewPoint(list,varargin),

parm = struct;

for i = 1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    eval(['parm.' key ' = val;']);
end

diary([list '.vpClassifier.' date '-' datestr(now, 'HH:MM:SS') '.log']);

dbstop if error;

parm.fct = 0.2;

if ~isfield(parm,'sizeRoot'),
	parm.sizeRoot = [10 10]; % 8x8 bbox, 2 hog cell padding (4x4), 12x12 repn, after hog becomes 10x10.
end

parm.featDim = 32;

if ~isfield(parm,'sbin'),
	parm.sbin = 8;
end

if ~isfield(parm,'padHog'),
	parm.padHog = 2;
end

if ~isfield(parm,'sanityChecks'),
	parm.sanityChecks = 1;
end

%if ~isfield(parm,'DEPTH_DIR'),
%	parm.DEPTH_DIR = 'parts_depths/depths';
%end

parm.rootLength = prod([parm.sizeRoot parm.featDim]);
parm.sizeBBOX = parm.sizeRoot + 2*parm.padHog - 2;

if ~isfield(parm,'c'),
	parm.c = 1;
end

if ~isfield(parm,'e'),
	parm.e = 0.001;
end

parm.dimension = parm.numViews*prod([parm.sizeRoot parm.featDim]);

X = {};
Y = {};

%% prepare Data
lines = textread(list,'%s');
parm.numSamples = length(lines);
fprintf('NUMLINES READ: %d\n',parm.numSamples);

parm

for sample = 1 : parm.numSamples,
	[pat fil ext] = fileparts(lines{sample});
	%depth_im = imread(fullfile(parm.DEPTH_DIR,[fil '.png']));
	depth_im = imread(fullfile(pat,[fil ext]));
	%depth_im = padarray(depth_im,[parm.padHog parm.padHog]*parm.sbin,255); %% adding 2 strips of hog cells.
	im = depth_im;
	im = imresize(im,(parm.sizeRoot+2)*parm.sbin);
	%im       = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
	hog = features(double(im),parm.sbin);
	%assert(all(size(hog) == [10 10 32]));
	X{sample} = hog;
	y.viewPoint = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	Y{sample} = y;
end

%% let's learn some SVMs
parm.patterns = X;
parm.labels = Y;
parm.lossFn = @loss_vp;
parm.featureFn = @mypsi_vp;
parm.constraintFn = @mvc_vp;

model = svm_struct_learn(sprintf('-c %f -e %f -v 3 ',parm.c,parm.e), parm);
avgLoss = getPredictionLoss(parm,model);
fprintf('Average Prediction Loss per Sample: %g\n',avgLoss);
diary off;

save([list sprintf('vp%d.C%g',parm.numViews,parm.c) '.mat'],'parm','model','-v7.3');

end

function [avgLoss] = getPredictionLoss(parm,model),
	avgLoss = 0;
	fprintf('Losses: ');
	for sample = 1 : parm.numSamples,
		yhat = predict_vp(parm,model,parm.patterns{sample});
		sampleLoss = loss_vp(parm,parm.labels{sample},yhat);
		fprintf('%g ',sampleLoss);
		avgLoss = avgLoss + sampleLoss;
	end
	fprintf('\n');
	avgLoss = avgLoss / parm.numSamples;
end
