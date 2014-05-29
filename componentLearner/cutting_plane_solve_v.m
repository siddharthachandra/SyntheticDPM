function [parm] = cutting_plane_solve_p(parm,model),
	%%%%% We are optimizing the function C_1\Xi_i + C_2\Xi_j, subject to constraints on p.
	lpparm.lb = [zeros(parm.N1+parm.N2,1);0;0]; %v's followed by the two slacks.
	lpparm.ub = [ones(parm.N1+parm.N2,1);Inf;Inf]; %v's followed by the two slacks.
	lpparm.f  = [zeros(parm.N1+parm.N2,1);parm.c1;parm.c2];
	
	dbstop if error
	lpparm = struct; %linear programming parameters.
	lpparm.A = [];
	lpparm.b = [];
	lpparm.Aeq = zeros(parm.numViews, ( (parm.numParts + 1) * parm.numViews ) + 1); % the last ones (parm.numParts + *1* ) for constant terms. finally another 1 for the \Xi
	lpparm.beq = zeros(parm.numViews,1);
	lpparm.lb = zeros(((parm.numParts+1)*parm.numViews)+1,1);
	lpparm.ub = zeros(((parm.numParts+1)*parm.numViews)+1,1);
	opts = optimset('Display','off');
	%opts = optimset('Display','iter');
	%%%
	offSets = zeros(1,parm.numViews);
	for view = 1 : parm.numViews,
		indices = find([parm.visibleParts{view} 1]);
		offset = (view - 1)*(parm.numParts + 1);
		offSets(view) = offset;
		lpparm.Aeq(view,indices+offset) = 1;
		lpparm.ub(indices+offset) = 1;
		lpparm.lb(indices(end)+offset) = 1;
		lpparm.beq(view) = parm.allowedParts + 1;
	end
	%% upper bound on \Xi
	lpparm.ub(end) = Inf;
	%% feasible p

	for view = 1 : parm.numViews,
		p = parm.visibleParts{view};
		fprintf('view %d visible: %s\n',view,num2str(find(p)));
		p = find(p);
		p = p(randperm(length(p)));
		p = p(1:parm.allowedParts);
		pp = zeros(1,parm.numParts);
		pp(p) = 1;
		parm.partIndicators{view} = pp;
	end

	%% single LP
	iter = 0;
	%% find objective function.
	objFunc = (zeros( ((parm.numParts+1)*parm.numViews) + 1,1));
	objFunc(end) = parm.c / parm.numSamples;
	indx = 1 : parm.numParts + 1; 

	oldObj = 0;
	oldXi = -Inf;
	while 1,
		iter = iter + 1;

		%% find most violated constraint	
		clear f;
		f = (zeros( ((parm.numParts+1)*parm.numViews) + 1,1));
		f(end) = -1;
		for sample = 1 : parm.numSamples,
    	    view = parm.labels{sample}.viewPoint;
        	[ywhat, maxScore, rootScore, partScore] = mvc(parm,model,parm.patterns{sample},parm.labels{sample});
	        [gt_rootScore,gt_partScores,gt_totalScore] = gt_score(parm,model.w,parm.patterns{sample},parm.labels{sample});
    	    constant_part = rootScore - gt_rootScore;
        	if view ~= ywhat.viewPoint, %% the loss is a constant.
            	constant_part = constant_part + 1;
	        end
    	    f(indx + offSets(view)) = f(indx + offSets(view)) + [partScore - gt_partScores; constant_part];
	    end

		lpparm.A = [lpparm.A; f'];
		lpparm.b = [lpparm.b; 0 ]; 

		if parm.sanityChecks,
			obj = getobj(parm,model);
			obj2 = getobj2(parm,model);
			original = sum(f(1:end-1));
			assert(abs(original - obj) < 1e-3);
			assert(abs(original - obj2) < 1e-3);
			%fprintf('PASSED\n');
		end
		%% initial solution p0
		p0 = zeros(size(f));
		for view = 1 : parm.numViews,
			p0(indx + offSets(view)) = [parm.partIndicators{view}'; 1];
		end

		[sol func_val] = linprog(objFunc,lpparm.A,lpparm.b,lpparm.Aeq,lpparm.beq,lpparm.lb,lpparm.ub,p0,opts);
		p = sol(1:end-1);
		%keyboard;
		Xi = sol(end);
		if parm.sanityChecks,
			assert(Xi - oldXi + 1e-4 >= 0);
		end
		%keyboard;
		for view = 1 : parm.numViews,
			p_ = p(indx + offSets(view));
			%find(p_>1e-3)'
			%p_(find(p_>1e-3))'
			p_ = p_(1:end-1);
			p_ = p_';

			inds = find(p_ > 1e-3 );
			vals = p_(inds);
			inds_vals = reshape([inds;vals],1,[]);
			fprintf('view %d chosen: ',view);
			fprintf('%d(%g) ; ',inds_vals);
			fprintf('\n');
			if parm.sanityChecks,
				assert(length(p_) == parm.numParts);
			end
			parm.partIndicators{view} = p_;
		end
		if iter<2,
			fprintf('View: %d. Cutting plane iteration %d. Function Value: %g. Virt-obj: %g\n',view,iter,func_val,parm.c*(sum(f(1:end-1)/parm.numSamples)));
		else
			fprintf('View: %d. Cutting plane iteration %d. Function Value: %g. New Xi - old Xi: %g. Virt-obj: %g \n',view,iter,func_val,Xi - oldXi,parm.c*(sum(f(1:end-1)/parm.numSamples)));
		end
		%keyboard;

		%% convergence criterion should be: NO NEW CONSTRAINTS.
		%fprintf('MOST VIOLATED CONSTRAINTS: %g\n',sum(f));
		if iter>1 && Xi - oldXi <= parm.e,
			fprintf('Cutting plane converged at iteration %d. Function Value: %g\n',iter,func_val);
			break;
		end
		oldXi = Xi;
	end %% cutting plane ends here.
	%% restore indicator vectors to integer values.
	for view = 1 : parm.numViews,
		p = parm.partIndicators{view};
		[val pos] = sort(p,'descend');
		pos = pos(1:parm.allowedParts);
		p = zeros(size(p));
		p(pos) = 1;
		parm.partIndicators{view} = p;
	end
end
