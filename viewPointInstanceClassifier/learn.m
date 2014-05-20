%trainViewPoint('synthetic.bed4.3instances')

for c = [ 0.01 0.1 1 10 100 1000]
	trainViewPoint('synthetic4.monitor.5instances','c',c);
end
