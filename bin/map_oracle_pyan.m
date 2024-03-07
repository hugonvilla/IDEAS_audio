function SPM = map_oracle_pyan(Vadpy,Vadn,SPn,Fs,Len)
%%%%% maps each oracle speaker to a single  pyannote speaker
USor = unique(SPn); %speaker IDs in oracle
USpy = unique(Vadpy(:,3)); %speakers in Pyannote
for i = 1:numel(USor) %for each Oracle speaker
    Vadi = Vadn(SPn == USor(i),:);
    Vadi=[floor(Vadi(:,1)*Fs+1) ceil(Vadi(:,2)*Fs+1)];
    mvadi = sigroi2binmask(Vadi,Len);
    for j = 1:numel(USpy) %for each Pyannote speaker
        Vadpj = Vadpy(Vadpy(:,3) == USpy(j),:);
        Vadpj=[floor(Vadpj(:,1)*Fs+1) ceil(Vadpj(:,2)*Fs+1)];
        mvadpj = sigroi2binmask(Vadpj,Len);
        Mij = mvadi.*mvadpj; %mask of common talk
        OD(i,j) = sum(Mij)/Fs; %overlapped talk duration in samples
    end
end
[~,idx] = max(OD,[],2); %index in USpy with highest overlap for each USor
SPM = table(USor,USpy(idx),'VariableNames',{'or','py'});
