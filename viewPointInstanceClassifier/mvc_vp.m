function [y_mvc,maxScore] = mvc(parm,model,x,y),
	w = model.w;
	maxScore = -Inf;
	bestV = -1;
	offSet = 1;
	y_mvc = y;
	for inst = 1 : parm.numInstances,
		for view = 1 : parm.numViews,
			rootScore = w(offSet:offSet+parm.rootLength-1)' * x(:);
			offSet = offSet + parm.rootLength; %%root filter.
			if view ~= y.viewPoint,
				rootScore = rootScore + 1;
			end
			if rootScore > maxScore,
				maxScore = rootScore;
				y_mvc.viewPoint = view;
				y_mvc.instance = inst;
			end
		end
	end
end
