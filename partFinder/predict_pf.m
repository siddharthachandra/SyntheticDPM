function yhat = predict(parm,model,x),
	w = model.w;
	maxScore = -Inf;
	bestV = -1;
	offSet = 1;
	yhat = struct;

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
	for view = 1 : parm.numViews,
		ywhat = struct;
		presence = parm.partIndicators{view};
		numActiveParts = sum(presence);
		
		score_view = 0; 
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
	            [v, YY] = max(score);
    	        [v, xp] = max(v);
        	    yp = YY(xp);
				yp = min(max(1,yp),parm.sizeRoot(1)-parm.sizeParts(1)+1);
	            xp = min(max(1,xp),parm.sizeRoot(2)-parm.sizeParts(2)+1);
				ps = [yp xp [yp xp]+(parm.sizeParts -1) 1];
				ywhat.parts{part} = ps;
				score_view = score_view + v;
			else,
				ywhat.parts{part} = [-1 -1 -1 -1 0];
			end
			offSet = offSet + parm.partLength;
		end
		if score_view > maxScore,
			maxScore = score_view;
			yhat = ywhat;
		end
	end
	%% sanity check
	if parm.sanityChecks,
		score = full(dot(model.w,mypsi_pf(parm,x,yhat)));
		assert(abs(score - maxScore) < 1e-3);
	end
end
