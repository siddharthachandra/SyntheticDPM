function feat = mypsi(parm,x,y)
	feat = zeros(parm.dimension,1);
	offset = 1;
	for comp = 1 : parm.numComps,
		if y.component(comp),
			feat(offset:offset+parm.rootLength-1) = y.component(comp)*x(:);
		end
		offset = offset + rootLength;
	end
	feat = sparse(feat);
end
