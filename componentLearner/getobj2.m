function obj = get_objective_val(parm,model)
	obj = 0;
	for sample = 1 : parm.numSamples,
		[ywhat, maxScore, rootScore, partScore] = mvc(parm,model,parm.patterns{sample},parm.labels{sample});
		myloss = loss(parm,parm.labels{sample},ywhat);
		s = double(dot(model.w,mypsi_parts(parm,parm.patterns{sample},parm.labels{sample})));
		sbar = double(dot(model.w,mypsi_parts(parm,parm.patterns{sample},ywhat)));
		obj = obj + myloss - s + sbar;
	end
end
