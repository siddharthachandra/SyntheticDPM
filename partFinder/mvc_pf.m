function [ywhat maxScore bestPartScores losses] = mvc(parm,model,x,y),
	w = model.w;
	maxScore = -Inf;
	bestPartScores = 0;
	bestV = -1;
	offSet = 1;
	y_mvc = y;

	%%%%%% for binary potentials
	if parm.useBinary,
		range_x = 1 : parm.sizeRoot(2) - parm.sizeParts(2) + 1;
		range_y = 1 : parm.sizeRoot(1) - parm.sizeParts(1) + 1;
		mat_x = repmat(range_x,length(range_y),1);
		mat_y = repmat(range_y',1,length(range_x));
		mat_x2 = mat_x.*mat_x;
		mat_y2 = mat_y.*mat_y;
	end
	%%%%%%
	parts_init = cell(1,parm.numParts);
	parts_init(:) = {[-1 -1 -1 -1 0]};
	for view = 1 : parm.numViews,
		score_view = 0; %score corresponding to this view.
		ywhat = struct;
		ywhat.parts = parts_init;
		loss_view = 0;	
		numActiveParts = 0; 
		y_parts_mat = cell2mat(y.parts');
		presence = parm.partIndicators{view}' .* y_parts_mat(:,end);
		numActiveParts = sum(presence);
		if parm.sanityChecks,
			if numActiveParts==0,
				%fprintf('WARNING: Number of Active Parts ZERO! MVC alleged view %d GT view %d\n',view,y.viewPoint);
				%find(parm.partIndicators{view})
				%find(y_parts_mat(:,end))'
			end
		end	
		partScores = zeros(parm.numParts,1);
		for part = 1 : parm.numParts,
			if presence(part),
				thisPartW = single(w(offSet:offSet+parm.partLength-1));
				binaryTerms = thisPartW(end-3:end);
				thisPartW = thisPartW(1:end-4);
				thisPartW = reshape(thisPartW,[parm.sizeParts parm.featDim]);
				score = fconv_var_dim(x,{thisPartW},1,1);
				score = score{1};
				if parm.useBinary,
					score = score + binaryTerms(1)*mat_y + binaryTerms(2)*mat_x + binaryTerms(3)*mat_y2 + binaryTerms(4)*mat_x2;
				end
				if 1 %view == y.viewPoint,
					%%%%% PART LOSS
					partLossMatrix = zeros([parm.sizeRoot - parm.sizeParts + 1]);
					for xx = 1 : parm.sizeRoot(2) - parm.sizeParts(2) + 1,
						for yy = 1 : parm.sizeRoot(1) - parm.sizeParts(1) + 1,
							if y.parts{part}(end), 
								partLossMatrix(yy,xx) = (1 - overlap(y.parts{part},[yy xx [yy xx]+parm.sizeParts-1]))/numActiveParts;
							end
						end
					end
					%%%%%%%%%%%
					score = score + partLossMatrix;
				end
	            [v, YY] = max(score);
    	        [v, xp] = max(v);
        	    yp = YY(xp);
				loss_view = loss_view + partLossMatrix(yp,xp);
				yp = min(max(1,yp),parm.sizeRoot(1)-parm.sizeParts(1)+1);
	            xp = min(max(1,xp),parm.sizeRoot(2)-parm.sizeParts(2)+1);
				ps = [yp xp [yp xp]+(parm.sizeParts -1) 1];
				ywhat.parts{part} = ps;
				score_view = score_view + v*presence(part);
				partScores(part) = v*presence(part);
			end
			offSet = offSet + parm.partLength;
		end
		if score_view > maxScore,
			maxScore = score_view;
			y_mvc = ywhat;
			bestPartScores = partScores;
			losses = loss_view;
		end
	end
	ywhat = y_mvc;
	if parm.sanityChecks,
		score_gt = full(dot(w,mypsi_parts_pf(parm,x,y)));
		score_mvc= full(dot(w,mypsi_parts_pf(parm,x,y_mvc)));
		myloss = loss_pf(parm,y,y_mvc);
		slack = score_mvc + myloss - score_gt;
		%assert(abs(score_mvc + myloss - maxScore)<1e-3);
		assert(slack>=0);
	end
end

function o = overlap(bbox1, bbox2), %gives intersection over union of 2 bboxes specified as [y x Y X] 
    y1 = max(bbox1(1), bbox2(1));
    x1 = max(bbox1(2), bbox2(2));
    y2 = min(bbox1(3), bbox2(3));
    x2 = min(bbox1(4), bbox2(4));
    w = x2-x1+1;
    h = y2-y1+1;
    if w<0 || h<0,
        o = 0;
        return;
    end
    inter = w*h;
    aarea = (bbox1(3)-bbox1(1)+1) * (bbox1(4)-bbox1(2)+1);
    barea = (bbox2(3)-bbox2(1)+1) * (bbox2(4)-bbox2(2)+1);
    % intersection over union overlap
    o = inter / (aarea+barea-inter);
end
