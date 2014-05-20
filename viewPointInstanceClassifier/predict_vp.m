function [yhat scores] = predict_vp(parm,model,x),
	w = model.w;
	maxScore = -Inf;
	offSet = 1;
	yhat = struct;
	scores = zeros(parm.numInstances,parm.numViews);
	for inst = 1 : parm.numInstances,
		for view = 1 : parm.numViews,
			rootScore = w(offSet:offSet+parm.rootLength-1)' * x(:);
			offSet = offSet + parm.rootLength; %%root filter.
			scores(inst,view) = rootScore;
			if rootScore > maxScore,
				maxScore = rootScore;
				yhat.viewPoint = view;
				yhat.score = maxScore;
				yhat.instance = inst;
			end
		end
	end
end
