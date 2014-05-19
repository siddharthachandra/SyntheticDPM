function obj = get_objective_val(parm,model)
	obj = 0;
	for sample = 1 : parm.numSamples,
		[ywhat, maxScore, partScore] = mvc_pf(parm,model,parm.patterns{sample},parm.labels{sample});
		[gt_partScores,gt_totalScore] = gt_score_pf(parm,model.w,parm.patterns{sample},parm.labels{sample});
%		fprintf('sample:%d mvc:%g gt:%g\n',sample,maxScore,gt_totalScore);
		obj = obj + maxScore - gt_totalScore;
	end
end
