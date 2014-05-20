function [delta] = loss(parm,y,ybar), %% Prediction LOSS
	delta = double(y.viewPoint ~= ybar.viewPoint);
end
