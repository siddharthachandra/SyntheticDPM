function feat = mypsi(parm,x,y)
	sizeFeat = parm.numViews*( parm.rootLength + parm.numParts * parm.partLength);
	feat = zeros(sizeFeat,1);
	offset = (y.viewPoint - 1)*(parm.rootLength + parm.numParts*parm.partLength) + 1;
	feat(offset:offset+parm.rootLength-1) = x(:); %installing root
	offset = offset + parm.rootLength; %updating offset
	for part = 1 : parm.numParts,
		if parm.partIndicators{y.viewPoint}(part) && y.parts{part}(end),
			ps = y.parts{part}; %[y x Y X]
			partFeat = x(ps(1):ps(3),ps(2):ps(4),:);
			if parm.useBinary,
				binaryTerms = [ ps(1); ps(2); ps(1)^2; ps(2)^2];
			else
				binaryTerms = [0;0;0;0];
			end
			feat(offset:offset+parm.partLength-1) = parm.partIndicators{y.viewPoint}(part)*[partFeat(:); binaryTerms];
		end
		offset = offset + parm.partLength;
	end
	feat = sparse(feat);
end
