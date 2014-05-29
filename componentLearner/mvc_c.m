function [y_mvc,maxScore] = mvc(parm,model,x,y),
	w = model.w;
	maxScore = -Inf;
	bestV = -1;
	offSet = 1;
	y_mvc = y;
	scores = compScores(parm,model,x);

	Aeq = [ones(1,parm.numComps) 0];
	beq = 1;

	lb = [zeros(parm.numComps,1); 1];
	ub = ones(parm.numComps+1,1);

	for sgn = [-1,1],
		for dim = 1 : parm.numComps,
			coefficient = ones(parm.numComps,1);
			coefficient(dim) = -1;
			const_terms = sgn.*coefficient.*y.components;
			coefficient = -sgn.*coefficient;
			disp([const_terms  coefficient]);
			f = -1*[ scores + 0.5*coefficient ; 0.5*sum(const_terms) ];
			[v score_v] = linprog(f,[],[],Aeq,beq,lb,ub);
			score_v = -score_v;
			if score_v > maxScore,
				maxScore = score_v;
				y_mvc.component = v(1:end-1);
			end	
		end
	end
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
