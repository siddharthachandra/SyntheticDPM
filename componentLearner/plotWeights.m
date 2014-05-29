function plotWeights(model,parm),
	addpath vis;
	plot(model.w,parm);
end
function plot(w,parm),
	offset = 1;
	rootLength = prod([parm.sizeRoot parm.featDim]);
	partLength = prod([parm.sizeParts parm.featDim]);
	sizeFeat = parm.numViews*(prod([parm.sizeRoot parm.featDim]) + parm.numParts * prod([parm.sizeParts parm.featDim]));
	assert(sizeFeat == length(w));
	rows = 1 + 2 + 1;
	summ = 0;
	for view = 1:parm.numViews,
		clf;
		figure(view);
		root = w(offset:offset+rootLength-1); %installing root
		root = reshape(root,[parm.sizeRoot parm.featDim]);
		summ = summ + norm(root(:));
		subplot(rows,parm.allowedParts/2,[1,2,3,4,5,6,7,8]); imshow(HOGpicture(root,parm.sbin_vis),[]);
		offset = offset + rootLength; %updating offset
		seen = 8;
		row = 1;
		for part = 1 : parm.numParts,
			if parm.partIndicators{view}(part),
				seen = seen + 1;
				partFilter = w(offset:offset + partLength - 1);
				partFilter = reshape(partFilter,[parm.sizeParts parm.featDim]);
				subplot(rows,parm.allowedParts/2,seen); imshow(HOGpicture(partFilter,parm.sbin_vis),[]);
			end
			offset = offset + partLength;
		end
		print('-dpng',sprintf('%s/%s/filter_view_%d.png',parm.plotDir,parm.list,view));
	end
end
