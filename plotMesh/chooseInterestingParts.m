LISTNAME = 'listOfDats.monitortelevision.allViews'
numViews = 3
IMGDIR = 'parts_depths/depths'
ntop = 10;
c = 'g'; %green
cwidth = 1.4; %width of line
s = '-'; %line style
LIST = textread(LISTNAME,'%s');
numSamplesPerView = length(LIST)/numViews;
%%% generate statistics
numModels = length(LIST);
allParts = [];
for mdl = 1 : numModels,
	partImg = load(LIST{mdl});
	parts_present = unique(partImg(:));
	allParts = [allParts; parts_present];
end
bins = unique(allParts);
%partHist = hist(allParts,bins);

%% GET TOP PARTS
%[vals partIDs] = sort(partHist,'descend');
%partIDs = bins(partIDs);

for partNUM = 1 : length(bins),
	partID = bins(partNUM);
	for view = 1:numViews,
    	count = 0;
		for mdl = (view-1)*numSamplesPerView+1:(view-1)*numSamplesPerView+100, %randperm(numModels),
			partImg = load(LIST{mdl});
			if any(partImg(:) == partID),
				mask = partImg == partID;
	            %[y,x,Y,X] = bboxFromMask(mask);
				[dir fil] = fileparts(LIST{mdl});
				im = imread(fullfile(IMGDIR,[fil '.png']));
				im = imresize(im,size(mask));
				r = rgb2gray(im);
				g = r;
				b = r;
				r(mask) = 0;
				g(mask) = 255;
				b(mask) = 0;
				im = cat(3,r,g,b);
				imshow(im);
				%keyboard;
			    %line([x x X X x]', [y Y Y y y]', 'color', c, 'linewidth', cwidth, 'linestyle', s);
			    print('-dpng',sprintf('choose/part_%d_%s.png',partID,fil));
			    im = imread(sprintf('choose/part_%d_%s.png',partID,fil));
				im = removePadding_noslim(im);
				im = imresize(im,0.5);
				imwrite(im,sprintf('choose/part_%d_%s.png',partID,fil));
	            count = count + 1;
	            fprintf('part %d/%d view %d/%d image %d/%d\n',partNUM,length(bins),view,numViews,count,15);
	            if count >= 1,
	                break;
	            end
			end
		end
	end
end
