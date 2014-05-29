function [delta,deltas] = loss(parm,y,ybar), %% Prediction LOSS
	deltas = abs(y.component - ybar.component);
	delta = sum(deltas)/2;
end
