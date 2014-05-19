function [y,x,Y,X] = bboxFromMask(thisMask),
	[r c] = size(thisMask);
	for x = 1:c,
		if any(thisMask(:,x)),
			break;
		end
	end
	for X = c:-1:1,
		if any(thisMask(:,X)),
			break;
		end
	end
	for y = 1:r,
		if any(thisMask(y,:)),
			break;
		end
	end
	for Y = r:-1:1,
		if any(thisMask(Y,:)),
			break;
		end
	end
end
