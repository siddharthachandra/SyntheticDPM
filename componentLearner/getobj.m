function obj = get_objective_val(parm,model)
	obj = 0;
	for sample = 1 : parm.numSamples,
		[ywhat, maxScore, rootScore, partScore] = mvc(parm,model,parm.patterns{sample},parm.labels{sample});
		[gt_rootScore,gt_partScores,gt_totalScore] = gt_score(parm,model.w,parm.patterns{sample},parm.labels{sample});
		obj = obj + maxScore - gt_totalScore;
	end
end
