function [delta,deltas] = loss(parm,y,ybar), %% Prediction LOSS
	y_mat = cell2mat(y.parts');
	ybar_mat = cell2mat(ybar.parts');
	deltas = 1 - overlap_mats(y_mat,ybar_mat);
	presence = parm.partIndicators{1}' .* y_mat(:,end);
	deltas = presence .* deltas;
	numac = sum(presence);
	if numac,
		delta = sum(deltas)/numac;
	else,
		delta = 0;
	end
	if parm.sanityChecks,
		assert(delta>=0);
	end
end
function os = overlap_mats(mat1, mat2),
	y1 = max(mat1(:,1), mat2(:,1));
	x1 = max(mat1(:,2), mat2(:,2));
	y2 = min(mat1(:,3), mat2(:,3));
	x2 = min(mat1(:,4), mat2(:,4));
	w = x2-x1+1;
	h = y2-y1+1;
	inter = w .* h;
	aarea = (mat1(:,3)-mat1(:,1)+1) .* (mat1(:,4)-mat1(:,2)+1);
	barea = (mat2(:,3)-mat2(:,1)+1) .* (mat2(:,4)-mat2(:,2)+1);
	% intersection over union overlap
	os = inter ./ (aarea+barea-inter);
	os(w<0) = 0;
	os(h<0) = 0;
end
