function obj = get_objective_val(parm,model)
	obj = 0;
	for sample = 1 : parm.numSamples,
		[ywhat, maxScore, partScore] = mvc_pf(parm,model,parm.patterns{sample},parm.labels{sample});
		myloss = loss_pf(parm,parm.labels{sample},ywhat);
		s = double(dot(model.w,mypsi_parts_pf(parm,parm.patterns{sample},parm.labels{sample})));
		sbar = double(dot(model.w,mypsi_parts_pf(parm,parm.patterns{sample},ywhat)));
%		fprintf('sample:%d mvc:%g(%g) gt:%g loss:%g\n',sample,maxScore,full(sbar),full(s),myloss);
		obj = obj + myloss - s + sbar;
	end
end
