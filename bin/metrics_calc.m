function [LM,AWO,LMB] = metrics_calc(TF)
%%%%%%% This script calculate metrics from IDEAS Data
%% CDS
AWM = TF.AWP;
AWO = table(AWM.spk_type,AWM.start_a,AWM.end_a,AWM.trans,AWM.otrans,AWM.conf,...
    'VariableNames',{'spk_type','start','end','trans','otrans','conf'}); %output diarization

Pname = unique(AWM.spk_type);

%% All recording
LM=[];
for jj = 1:length(Pname)  %for each speaker type
    AWMj = AWM(AWM.spk_type==Pname(jj),:);
    Lm = Lmeasures(AWMj.trans); %outgoing talk
    Cm = Cmeasures(AWM,Pname(jj));
    Am = table(Pname(jj),0,TF.TD,'VariableNames',{'SPKT','ON','OFF'});
    LMj = [Am Lm Cm];
    LM=[LM;LMj];
end

%%%% Batches
PA=parameters();
Cd = PA.Cd; %batch duration
Nchunks = ceil(TF.TD/Cd);
LMB=[];
fika=[];
for kj = 1:Nchunks
    Tok =  (kj-1)*Cd;
    Tfk = min((kj)*Cd,TF.TD);
    fik = find(AWM.start_a <=Tfk & AWM.end_a >= Tok);
    %fik = find(AWM.start_a >=Tok & AWM.end_a <= Tfk);
    fik = setdiff(fik,fika); %don't count utterances twice
    fika = unique([fika;fik]); %add indices
    
    AWMk = AWM(fik,:);

    for jj = 1:length(Pname)  %for each speaker type
        AWMkj = AWMk(AWMk.spk_type==Pname(jj),:);
        Lmb = Lmeasures(AWMkj.trans); %outgoing talk
        Cmb = Cmeasures(AWMk,Pname(jj));
        Amb = table(Pname(jj),Tok,Tfk,'VariableNames',{'SPKT','ON','OFF'});
        LMBj = [Amb Lmb Cmb];
        LMB=[LMB;LMBj];
    end
end
  









