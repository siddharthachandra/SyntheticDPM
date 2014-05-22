%trainViewPoint('synthetic.bed4.3instances')
categories = { 'monitortelevision','bed','chair','sofa','table'};
numC = length(categories);
for c = [ 0.01 0.1 1 10 100 1000]
	for cID = 1 : numC,
		trainViewPoint(categories{cID},'c',c);
	end
end
