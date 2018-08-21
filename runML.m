function out=runML(nTest,method,val_years,tablepath,...
    idx_p,idx_r,idx_v,varargin)
% general function to run machine learning by year
% Ned Bair, 8/2018
% use e.g. or example values to run the supplied example
% input -----
% nTest: test points for each year, e.g. 1e3
% method: ML method, 'NN' for neural network or 'ET' for ensemble or 'ET
% optimize' to optimize ET hyperparameters. Note if 'ET optimize'
% is supplied, then a 10th argument must be the hyperparameter
% file, created using 'ET optimize', see variable argument below, e.g.
% 'ET' or 'NN'
% val_years: vector of years, e.g. 2003:2004
% tablepath: where the tables with the predictors and targets live. Tables
% must be named YYYYTable.mat, with YYYY as a 4 digit year and must be 
% mat files with the following variables: DisplayNames (1xN) cell and 
% T (MxN) table, with M pixels each having N variables 
%(1 target and N-1 predictors)
% e.g. './sierra/'
% idx_p: vector of column indices to table containing predictors 
% idx_r: scalar column index to table for target (reponse) variable
% idx_v: scalar column index to table for validation variable
% For example, for the Sierra, these three variables would be:
%         idx_p=3:18; % predictors
%         idx_r=19; %response (recononstructed swe)
%         idx_v=20; %validation, (interpolated swe)
% variable argument:
% hyperparameter file, e.g. Sierra_optimized_hyperparameters.mat
% see the example mat file above for structure of this file
% output
% out, structure of errors and validation data

expectedmethods={'ET','NN','ET optimize'};
method=validatestring(method,expectedmethods);

v=load(fullfile(tablepath,sprintf('%iTable.mat',val_years(1))),'DisplayNames');
v.varnames=v.DisplayNames;
numVars=length(v.varnames); % total number vars
hyper=[];

predictorNames=v.varnames(idx_p);
bias_pct=zeros(size(val_years));
rmse_vec=zeros(size(val_years));

ydata=zeros([nTest length(val_years)]);
yfitdata=zeros([nTest length(val_years)]);
residuals=zeros([nTest length(val_years)]);

switch method
    case 'ET optimize'
        TreeMethod='Bag';
        t=loadData(val_years,numVars,nTest,v.varnames,tablepath);
        predictors = t(:, idx_p);
        response = t(:,idx_r);
        out = fitrensemble(...
        predictors, ...
        response, ...
        'Method',TreeMethod,'OptimizeHyperparameters','all');
        mname=[region,'_optimized_hyperparameters.mat'];
        if exist(mname,'file')==2
            delete(mname);
        end
        m=matfile(mname,'Writable',true);
        m.Method=TreeMethod;
        m.MaxNumSplits=out.HyperparameterOptimizationResults.XAtMinObjective.MaxNumSplits;
        m.MinLeafSize=out.HyperparameterOptimizationResults.XAtMinEstimatedObjective.MinLeafSize;
        m.NumLearningCycles=out.HyperparameterOptimizationResults.XAtMinEstimatedObjective.NumLearningCycles;
        m.NumVariablesToSample=out.HyperparameterOptimizationResults.XAtMinEstimatedObjective.NumVariablesToSample;
        if strcmp(TreeMethod,'Bag')
            imp=out.oobPermutedPredictorImportance;
        else
            imp=out.PredictorImportance;
        end
        [~,idx]=sort(imp,'descend');
        %plot predictor importance
        figure;
        bar(imp(idx),'FaceColor',[0.85 0.33 .1]);
        ylabel('predictor importance');
        set(gca,'XTick',1:length(idx),'XTickLabel',predictorNames(idx),'XTickLabelRotation',45,'FontSize',15);
        %plot correlation matrix
        figure;
        r=corrcoef([predictors response]);
        imagesc(r);
        h=colorbar;
        h.Label.String='r';
        caxis([0 1]);
        labels={predictorNames{:} v.varnames{idx_r}};
        set(gca,'XTick',1:15,'XTickLabel',labels,'YTick',1:15,'YTickLabel',labels,...
            'XTickLabelRotation',45,'YTickLabelRotation',45,'FontSize',15);
        set(gca,'TickLabelInterpreter','none');
        axis image;
    return
    case 'ET'
        hyperfile=varargin{1};
        hyper=load(hyperfile);
end

parfor j=1:length(val_years)
    tic
    yrs=val_years;
    validation_year=val_years(j); %year for validation
    yrs(yrs==validation_year)=[];
    t=loadData(yrs,numVars,nTest,v.varnames,tablepath);
    predictors = t(:, idx_p);
    response = t(:,idx_r);
    switch method
        case 'NN'
            net1=runNN(predictors,response);
        case 'ET'
            regressionEnsemble=runTrees(predictors,response,hyper);
    end
    %load validation year
    t=loadData(validation_year,numVars,nTest,v.varnames,tablepath);
    x=t(:,idx_p);
    y=t(:,idx_v); 
    
    switch method
        case 'NN'
            yfit = sim(net1,x')';
        case 'ET'
            yfit = regressionEnsemble.predict(x);
    end
    
    rmse_vec(j)=sqrt(mean(yfit-y).^2);
    bias_pct(j)=mean(yfit-y)./mean(y);
    ydata(:,j)=y;
    yfitdata(:,j)=yfit;
    residuals(:,j)=yfit-y;
    toc;
end

tit1=[method,' error, by year'];
tit2=[method,' residuals, by year'];

plot_errors(val_years,bias_pct,rmse_vec,tit1);
plot_residuals(val_years,residuals,tit2)

out.rmse_vec=rmse_vec;
out.bias_pct=bias_pct;
out.ydata=ydata;
out.yfitdata=yfitdata;

out.T=cell(3,length(val_years)+2);
out.T(1,2:2+length(val_years)-1)=num2cell(val_years);
out.T{1,length(val_years)+2}='mean';
out.T(2:3,1)={'RMSE';'bias_pct'};
out.T(2:3,2:2+length(val_years)-1)=...
    num2cell(round([out.rmse_vec;out.bias_pct*100]));
out.T(2:3,length(val_years)+2)=num2cell(round(mean(cell2mat(out.T(2:3,2:end-1)),2)));
end