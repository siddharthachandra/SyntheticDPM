function yhat = predict_vp(parm,model,x),
	w = model.w;
	maxScore = -Inf;
	offSet = 1;
	yhat = struct;

	for view = 1 : parm.numViews,
		rootScore = w(offSet:offSet+parm.rootLength-1)' * x(:);
		offSet = offSet + parm.rootLength; %%root filter.
		if rootScore > maxScore,
			maxScore = rootScore;
			yhat.viewPoint = view;
			yhat.score = maxScore;
		end
	end
end
