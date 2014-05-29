models = textread('models.txt','%s');
numModels = length(models);
colors = {'y','m','c','r','g','b','w','k'};
s = '-';
cwidth = 1.2;
addpath vis;
parm.sizeParts = [3 3];
parm.sizeRoot = [10 10];
parm.allowedParts = 8;
parm.numViews = 3;
parm.featDim = 32;
parm.widthX = 6;
parm.widthY = 6;
parm.widthZ = 6;
parm.sbin = 8;
parm.numParts = parm.widthZ*parm.widthY*parm.widthX; %prod(parm.sizeRoot - parm.sizeParts + 1);
parm.plotDir = 'learntParts_color'

for mdlID = 1 : 1, %numModels,
	load([models{mdlID} '.mat']); %gives indicators!!
	parm.partIndicators = indicators;
	clear indicators;
	samples = textread(models{mdlID},'%s');
	numsamples = length(samples);
	numSamplesPerView = round(numsamples/parm.numViews);
	mkdir(sprintf('%s/%s',parm.plotDir,models{mdlID}));
	for imgIndex = 1 : numsamples, %% loop over views, show parts per view.
	%for view = 1 : parm.numViews, %% loop over views, show parts per view.
		%imgIndex = (view-1)*numSamplesPerView + 1;
		img = imread(samples{imgIndex});
		img = imresize(img,(parm.sizeRoot+2)*parm.sbin);
		root = features(double(img),parm.sbin);
		rootIMG = HOGpicture(root,parm.sbin); %% 20, to produce a bigger image.
		clf;
		imshow(rootIMG);
		%set(gca, 'Units', 'normalized', 'Position', [0 0 1 1]);axis tight;
		print('-dpng',sprintf('%s/%s/sample_%d_a_root.png',parm.plotDir,models{mdlID},imgIndex));
		im = imread(sprintf('%s/%s/sample_%d_a_root.png',parm.plotDir,models{mdlID},imgIndex));
		im = removePadding(im);
		imwrite(im,sprintf('%s/%s/sample_%d_a_root.png',parm.plotDir,models{mdlID},imgIndex));
		numParts = length(parm.partIndicators{view});
		prediction = predict(parm,model,root);
		for part = 1 : length(prediction.parts),	
				t = prediction.parts{part}(1)*parm.sbin;
				l = prediction.parts{part}(2)*parm.sbin;
				b = prediction.parts{part}(3)*parm.sbin;
				r = prediction.parts{part}(4)*parm.sbin;
				part_identity = prediction.parts{part}(5);
				clf;
				imshow(rootIMG);
				line([l l r r l]', [t b b t t]', 'color', c, 'linewidth', cwidth, 'linestyle', s);
				print('-dpng',sprintf('%s/%s/sample_%d_b_part_%d_%d.png',parm.plotDir,models{mdlID},imgIndex,part,part_identity));
				im = imread(sprintf('%s/%s/sample_%d_b_part_%d_%d.png',parm.plotDir,models{mdlID},imgIndex,part,part_identity));
				im = removePadding(im);
				imwrite(im,sprintf('%s/%s/sample_%d_b_part_%d_%d.png',parm.plotDir,models{mdlID},imgIndex,part,part_identity));
		end
	end %% loop over views ends here.
end %% loop over models ends here.
