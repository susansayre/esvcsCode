clear all; close all;
dbstop if error
global G;

runID = datestr(now,'yyyymmdd_HHMMSS');
outputPath = fullfile('storedOutput',runID);
if ~exist(outputPath,'dir')
    mkdir(outputPath)
end

%normalize everything on mean env value = 10 and variance env value = 1;
%This implies that the likelihood of negative env values is extremely
%small;

%constant parameters
meanEnv = 10;
varEnv = 1;
delta = .95;

compStat = {
    'muValRat',     'ratio of mean v1 to mean env',                     [1.5];
    'varValRat',    'ratio of the variance of v1 to variance of env',	[.5, 1.5];
    'varVCRat',     'ratio of the variance of vc to variance of v1',    [0]; %0 means value change is constant
    'rhoEV',        'covariance between de and dv',                     [-.5];
    'rhoEVC',       'covariance between de and dvc',                    [0];
    'rhoVVC',       'covariance between dv and dvc',                    [0];
    'vardvRat',     'ratio of the variance of dv to variance of v1',    [.25,.75];
    'vardvcRat',    'ratio of the variance of dvc to variance of vc',   [1]; %1 means no random value change
    'muValChangeP', '% increase in mean value',                         [0]; %0 means no trend in value
};

prepareCompStatArray
randomizationStructure

%conduct the comparative static loops
for ii=1:size(valArray,1)
%for ii=1:1
    
    for jj=1:length(compStat)
        eval([compStat{jj,1} ' = valArray(ii,jj);'])
    end
    
    %call script to compute A, mu, and sigma matrices/vectors from the
    %compStat parameters for this case
    computeMats
    
    %use quadrature to generate two separate samples for random variables
    drawRandoms
    
    %next steps -- figure out how regulator optimizes given samples. Inner
    %optimization is for each parcel, across possible randMat draws
    
    %outer optimization will be across detMat draws because they aren't
    %known a priori. Have to account for the possibility that only certain
    %parcels will remain convertible in period 1.
end
    
    