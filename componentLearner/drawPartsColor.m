function drawPartsColor(model,parm),
	samples = textread(parm.list,'%s');
	numsamples = length(samples);
	for imgIndex = 1 : numsamples, %% loop over views, show parts per view.
		[pat fil ext] = fileparts(samples{imgIndex});
		part_im = load(fullfile(parm.PART_INDICATORS_DIR,[fil '.dat']));
		depth_im = imread(fullfile(parm.DEPTH_DIR,[fil '.png']));
		depth_im = imresize(depth_im,size(part_im)); %%depth and part images are the same size now.
        depth_im = padarray(depth_im,[3 3]*parm.sbin,255); %% adding 3 strips of hog cells.
        im       = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
        root = features(double(im),parm.sbin);
		rootIMG = HOGpicture(root,parm.sbin); %% 20, to produce a bigger image.
		clf;
		imshow(rootIMG);
		prediction = predict(parm,model,root);
		view = prediction.viewPoint;
		for part = 1 : length(prediction.parts),	
			t = prediction.parts{part}(1)*parm.sbin;
			l = prediction.parts{part}(2)*parm.sbin;
			b = prediction.parts{part}(3)*parm.sbin;
			r = prediction.parts{part}(4)*parm.sbin;
			part_identity = prediction.parts{part}(5);
			line([l l r r l]', [t b b t t]', 'color', parm.colors{part}, 'linewidth', parm.cwidth, 'linestyle', parm.s);
		end
		print('-dpng',sprintf('%s/%s/sample_%d_view_%d.png',parm.plotDir,parm.list,imgIndex,view));
		im = imread(sprintf('%s/%s/sample_%d_view_%d.png',parm.plotDir,parm.list,imgIndex,view));
		im = removePadding(im);
		imwrite(im,sprintf('%s/%s/sample_%d_view_%d.png',parm.plotDir,parm.list,imgIndex,view));
	end %% loop over samples ends here.
end
