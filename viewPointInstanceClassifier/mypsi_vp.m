function feat = mypsi(parm,x,y)
	feat = zeros(parm.dimension,1);
	offset = (y.instance - 1)*parm.numViews*parm.rootLength + (y.viewPoint - 1)*parm.rootLength + 1;
	feat(offset:offset+parm.rootLength-1) = x(:); %installing root
	feat = sparse(feat);
end
