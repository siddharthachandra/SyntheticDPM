function f=extractDisp(f,fsz,interval_endpoints,nrParams)
	% greg, 17/2: Added here this function to find the respective feats, since
	% we actually have the depth map 

	middle=floor((fsz+mod(fsz,2))/2);
	avgMiddle=f(middle(1),middle(2));
	N=size(interval_endpoints,2)-2;
	diff=f-avgMiddle;
	
	
	% greg, 18/5: new vectorised version
	inter(1,1,:)=interval_endpoints;
	inter=repmat(inter,[fsz(1),fsz(2),1]);
	positives=(diff>=0);   % save the positives
	diff=abs(diff);
	diff2=repmat(diff,[1,1,size(interval_endpoints,2)]);
	[~,pos1]=max(diff2-inter<0,[],3);  % find the differences from all intervals and then find the biggest non-negative
	feat3=(pos1+N-1).*positives+(N+3-pos1).*(1-positives); % indices of the features 
	
	% make feat3 from 2d matrix the 3d required for the features
	rowv=repmat([1:fsz(1)],[1,fsz(2)]);
	colv=repmat([1:fsz(2)],[fsz(1),1]);
	colv=colv(:);
	f1=zeros([numel(f)*nrParams,1]);
	f1(rowv'+(colv-1)*fsz(1)+(feat3(:)-1)*fsz(1)*fsz(2))=1;
	f=reshape(f1,[fsz(1),fsz(2), nrParams]);

end
