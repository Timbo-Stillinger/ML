function t=loadData(yrs,numVars,nTest,varnames,tablepath,varargin)
%input
% yrs, vector of input years
% numVars, how many variables to load
% nTest, # of random obs to collect from each year
% fsca_nullval, null value for fsca, e.g. 200
% varnames, cell of variable names
% tablepath, where do the tables live
% optional - basin number
%output
% t an m x numVars matrix

t=zeros(nTest,numVars,length(yrs));
fsca_nullval=200;
fsca_ind=strcmpi('FSCA',varnames);
swe_ind=strcmpi('Mean reconstructed SWE',varnames);
basin_ind=strcmpi('Basin',varnames);

basin_num=[];
if length(varargin)==1
    basin_num=varargin{1};
end
parfor i=1:length(yrs)
    m=matfile(fullfile(tablepath,sprintf('%iTable.mat',yrs(i))));
    T=m.T; %can't index randomly
    %drop: null fsca, zero fsca, zero swe values (sometimes happens w/ +
    %fsca and no cc), and out of basin obs
    ind=T(:,fsca_ind)==fsca_nullval | ...
        T(:,fsca_ind)==0 | ...
        T(:,swe_ind)==0 | ...
        T(:,basin_ind)==0 ;
        T(ind,:)=[];
    %drop out of basin values, if specified
    if ~isempty(basin_num)
        ind=T(:,basin_ind)~=basin_num;
        T(ind,:)=[];
    end
%     xmin=1;
%     xmax=length(T);
%     ind=round(xmin+rand(1,nTest)*(xmax-xmin));
    ind=randi(length(T),nTest,1);
    t(:,:,i)=T(ind,:);
end
% stack 3rd dimension 
t=reshape(permute(t,[1 3 2]),[size(t,1)*size(t,3) size(t,2)]);