function feat = mypsi(parm,x,y)
	feat = zeros(parm.dimension,1);
	offset = 1;
	for part = 1 : parm.numParts,
		if parm.partIndicators{1}(part) && y.parts{part}(end),
			ps = y.parts{part}; %[y x Y X]
			partFeat = x(ps(1):ps(3),ps(2):ps(4),:);
			if parm.useBinary,
				binaryTerms = [ ps(1); ps(2); ps(1)^2; ps(2)^2];
			else
				binaryTerms = [0;0;0;0];
			end
			feat(offset:offset+parm.partLength-1) = parm.partIndicators{1}(part)*[partFeat(:); binaryTerms];
		end
		offset = offset + parm.partLength;
	end
	feat = sparse(feat);
end
