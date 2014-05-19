function [partScores,totalScore] = gt_score(parm,w,x,y),
	partScores = zeros(parm.numParts,1);
	offset = 1;
	totalScore = 0;
	for part = 1 : parm.numParts,
		if parm.partIndicators{1}(part) && y.parts{part}(end),
			ps = y.parts{part}; %[y x Y X]
			partFeat = x(ps(1):ps(3),ps(2):ps(4),:);
			thisPartW = w(offset:offset+parm.partLength-1);
			binaryW = thisPartW(end-3:end);
			thisPartW = thisPartW(1:end-4);
			unaryScore = thisPartW' * partFeat(:);
			if parm.useBinary,
				binaryTerms = [ ps(1); ps(2); ps(1)^2; ps(2)^2];
				binaryScore = binaryW' * binaryTerms;
				unaryScore = unaryScore + binaryScore;
			end
			partScores(part) = unaryScore*parm.partIndicators{1}(part);
			totalScore = totalScore + partScores(part);
		end
		offset = offset + parm.partLength;
	end
end
