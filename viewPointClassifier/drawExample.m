expName = 'mn.list';
load([expName '.0002.mat']);
parm.list = expName;
parm.listStats = 'mn.list';
parm.colors = {'y','m','c','r','g','b','w','k'}; 
parm.s = '-'; 
parm.cwidth = 1.4;
parm.plotDir = 'learntParts_color';
parm.PART_INDICATORS_DIR = 'parts_depths/parts/';
parm.DEPTH_DIR = 'parts_depths/depths';
parm.sbin_vis = 20;
addpath vis;
parm
mkdir(sprintf('%s/%s',parm.plotDir,parm.list));
%plotWeights(model,parm);

for view = 1 : parm.numViews,
	averagePartLocations(view,parm);
end

%drawPartsColor(model,parm);
