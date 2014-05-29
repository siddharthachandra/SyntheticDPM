function [rootScore,partScores,totalScore] = gt_score(parm,w,x,y),
	partScores = zeros(parm.numParts,1);
	%sizeFeat = parm.numViews*( parm.rootLength + parm.numParts * parm.partLength);
	%feat = zeros(sizeFeat,1);
	offset = (y.viewPoint - 1)*(parm.rootLength + parm.numParts*parm.partLength) + 1;
	rootScore = w(offset:offset+parm.rootLength-1)' * x(:); %installing root
	totalScore = rootScore;
	offset = offset + parm.rootLength; %updating offset
	for part = 1 : parm.numParts,
		if parm.partIndicators{y.viewPoint}(part) && y.parts{part}(end),
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
			partScores(part) = unaryScore*parm.partIndicators{y.viewPoint}(part);
			totalScore = totalScore + partScores(part);
		end
		offset = offset + parm.partLength;
	end
end
