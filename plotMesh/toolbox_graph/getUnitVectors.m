function uVs=getUnitVectors(gridSize),
unitVsample = linspace(0,1,gridSize);
[uX uY uZ] = meshgrid(unitVsample);
uVs = [uX(:) uY(:) uZ(:)];
uVs = uVs(2:end,:);
normSum = sqrt(uVs(:,1).*uVs(:,1) + uVs(:,2).*uVs(:,2) + uVs(:,3).*uVs(:,3));
uVs = bsxfun(@rdivide,uVs,normSum);
uVs = unique(uVs,'rows');
end