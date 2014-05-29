function [y_mvc,maxScore] = mvc(parm,model,x,y),
	w = model.w;
	maxScore = -Inf;
	bestV = -1;
	offSet = 1;
	y_mvc = y;

	scores = compScores(parm,model,x);

	Aeq = [ones(1,parm.numComps)];
	beq = 1;

	lb = zeros(parm.numComps,1);
	ub = ones(parm.numComps+1,1);

	f = -1*[scores];
	[v score_v] = linprog(f,[],[],Aeq,beq,lb,ub);
	y_mvc.component = v;

end
function scores = compScores(parm,model,x),
	offset = 1;
	scores = zeros(parm.numComps,1);
	for comp = 1 : parm.numComps,
		feat = model.w(offset:offset+parm.rootLength-1);
		offset = offset + parm.rootLength;
		scores(comp) = feat.*x(:);
	end
end
