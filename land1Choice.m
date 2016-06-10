function [expRegVal,expLandVal] = land1Choice(offer1,privRands,randValues,G,caseID)
disp('starting land1Choice')
%extract/set values that are constant over the looping
try
   load(['solGuesses/' caseID])
catch
    period1Choice = G.ind.choice.delay*ones(size(randValues,1),1); %initialize all parcels to delay
    offer0 = 0.5*mean(randValues(:,:,G.ind.reg2rand.vpriv2,:),2) - 0.5*mean(randValues(:,:,G.ind.reg2rand.epriv,:),2);
end

numChange = 10;
iter = 0;
maxOffer = squeeze(max(randValues(:,:,G.ind.reg2rand.vpriv2,:),[],2));
choices(:,G.ind.choice.convert) = privRands(:,2)*(1+G.vprivGr*G.payoff2Factor);
choices(:,G.ind.choice.conserve) = (offer1(G.ind.offer1.perm)+privRands(:,1))*(1+G.payoff2Factor);

options = optimset('Display','off','MaxFunEvals',10e5);
% options.showiter = 0;
% options.tol = 1e-4;
while numChange>0
    iter = iter+1;
    period1ChoiceOld = period1Choice;
    %predict regulator choice given a set of period1 choices by landowners
    for ii=1:size(randValues,4)
        %[offerVector2,fval,exf] = genetic('regObj2',[0*maxOffer maxOffer],options,p1ChoiceMat,randArrayStruct.reg2,randWgtStruct.reg2);
        thisOffer0 = offer0(:,ii).*(period1Choice==G.ind.choice.delay);
        test = regObj2(thisOffer0,period1Choice,randValues(:,:,:,ii),G);
        [optOffer,fval,exf] = fmincon(@(x) regObj2(x,period1Choice,randValues(:,:,:,ii),G),thisOffer0,[],[],[],[],0*thisOffer0,maxOffer(:,ii),'',options);
        optOffers(:,ii) = optOffer;      
        nonConvertibleParcels = find(period1Choice~=G.ind.choice.delay);
        [expPayoffReg2(ii),expPayoffLand2(:,ii)] = regObj2(optOffer,period1Choice,randValues(:,:,:,ii),G);
        for jj=1:numel(nonConvertibleParcels) 
            thisPeriod1Choice = period1Choice;
            thisInd = nonConvertibleParcels(jj);
            thisPeriod1Choice(thisInd) = G.ind.choice.delay;
            [thisOptOffer,thisfval,thisexf] = fmincon(@(x) singleObj(x,thisInd,optOffer,thisPeriod1Choice,randValues(:,:,:,ii),G),privRands(thisInd,1),[],[],[],[],0,maxOffer(thisInd,ii),'',options);
            [~,expPayoffLand2(thisInd,ii)] = singleObj(thisOptOffer,thisInd,optOffer,thisPeriod1Choice,randValues(:,:,:,ii),G);
        end
    end
    expValDelay = mean(expPayoffLand2,2); %integrate out envD, v1D, v2D, v2, and env to get expectation of landowner
    %expValDelay is v1Cases x 1;
    choices(:,G.ind.choice.delay) = offer1(G.ind.offer1.temp) + G.payoff2Factor*expValDelay; 
    [expLandVal,period1Choice] = max(choices,[],2);
    numChange = numel(find(period1Choice-period1ChoiceOld));
    fprintf('%d\n',numChange);
    if iter==20
%         keyboard
    end
end

conserve = (period1Choice==G.ind.choice.conserve);
convert = (period1Choice==G.ind.choice.convert);
delay = (period1Choice==G.ind.choice.delay);

totalSvcs1 = squeeze(mean(repmat(conserve+delay,1,size(randValues,2),size(randValues,4)).*squeeze(randValues(:,:,G.ind.reg2rand.epub,:)))); %averages across parcels
expectedEnvPayoff1 = mean(mean(totalSvcs1 + G.envQuad*totalSvcs1.^2)); %averages across both sets of randomness

totalConv1 = squeeze(mean(repmat(convert,1,size(randValues,2),size(randValues,4)).*squeeze(randValues(:,:,G.ind.reg2rand.vpub,:))));
expConvPayoff = mean(mean(totalConv1));
expRegVal = expectedEnvPayoff1 + expConvPayoff - mean(expPayoffReg2)*G.payoff2Factor;

if exist('caseID','var')
    if ~exist('solGuesses','dir')
        mkdir('solGuesses')
    end
    offer0 = optOffers;
    save(['solGuesses/' caseID],'period1Choice','offer0')
end