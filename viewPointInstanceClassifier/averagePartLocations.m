function img = averagePartLocations(view,parm)
dbstop if error;

partTemplate = ones(parm.sizeParts*parm.sbin);
averageLocation = zeros(parm.numParts,3); %y,x,number_of_samples

%% prepare Data
lines = textread(parm.listStats,'%s');
parm.numSamples = length(lines);
fprintf('Finding average Part Locations. Number of synthetic images: %d\n',parm.numSamples);
%dbstop if error;
findRoot = 1;
for sample = 1 : parm.numSamples,
	view_sample = eval(lines{sample}(findstr(lines{sample},'.f')+2));
	if view ~= view_sample,
		continue;
	end
	[pat fil ext] = fileparts(lines{sample});
	part_im = load(fullfile(parm.PART_INDICATORS_DIR,[fil '.dat']));
	if findRoot,
		depth_im = imread(fullfile(parm.DEPTH_DIR,[fil '.png']));
		depth_im = imresize(depth_im,size(part_im)); %%depth and part images are the same size now.
		depth_im = padarray(depth_im,[3 3]*parm.sbin,255); %% adding 3 strips of hog cells.
		im       = imresize(depth_im,(parm.sizeRoot+2)*parm.sbin);
		root = features(double(im),parm.sbin);
		findRoot = 0;
	end
	part_im  = padarray(part_im, [3 3]*parm.sbin,0); %%adding 3 strips of black.
	part_im  = imresize(part_im, (parm.sizeRoot+2)*parm.sbin,'nearest');
	for part = 1 : parm.numParts,
		if parm.partIndicators{view}(part) && any(part_im(:) == part),
            score = conv2(single(part_im == part), partTemplate, 'valid');
			[v,YY] = max(score);
			[v,xp] = max(v);
			if v>parm.tolerance{view_sample}*sum(partTemplate(:)),%this part is present
				yp = YY(xp);
				averageLocation(part,1) = yp + averageLocation(part,1);
				averageLocation(part,2) = xp + averageLocation(part,2);
				averageLocation(part,3) = 1 + averageLocation(part,3);
			end
		end
	end
end
keyboard;
%% stats generated. Plot Average Part Locations NOW.
rootIMG = HOGpicture(root,parm.sbin); %% 20, to produce a bigger image.
clf;
imshow(rootIMG);
cInd = 0;
for part = 1 : parm.numParts,
	if parm.partIndicators{view}(part),	
		cInd = cInd + 1;
		num = averageLocation(part,3);
		yp  = averageLocation(part,1);
		xp  = averageLocation(part,2);
		if num,
			yp  = yp/num;
			xp  = xp/num;
			fprintf('part index %d id %d average pos [%g %g] out of %d instances.\n',cInd,part,yp,xp,num);
			t = yp; %min(max(1,round(yp)),parm.sizeRoot(1)-parm.sizeParts(1)+1);
			l = xp; %min(max(1,round(xp)),parm.sizeRoot(2)-parm.sizeParts(2)+1);
			b = t + (parm.sizeParts(1) - 1)*parm.sbin;
			r = l + (parm.sizeParts(2) - 1)*parm.sbin;
			line([l l r r l]', [t b b t t]', 'color', parm.colors{cInd}, 'linewidth', parm.cwidth, 'linestyle', parm.s);
		end 
	end
end
print('-dpng',sprintf('%s/%s/average_view__%d.png',parm.plotDir,parm.list,view));
im = imread(sprintf('%s/%s/average_view__%d.png',parm.plotDir,parm.list,view));
im = removePadding(im);
imwrite(im,sprintf('%s/%s/average_view__%d.png',parm.plotDir,parm.list,view));
