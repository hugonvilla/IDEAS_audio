function [SP,RES] = spk_identification(auout,Vad)

SP = strings(size(Vad,1),1);
RES=cell(1,1);

%%%%% Load parameters
PA = parameters();
Fs = PA.Fs;

%%%% Prepare classifier
iv=load(PA.Classif); 
iv=iv.iv;
if ~isempty(PA.ClassifGen)
    mdlg = load(PA.ClassifGen); mdlg=mdlg.mdl; %KNN classifier for generic classificationKNN
else
    mdlg=[];
end
if ~isempty(PA.ClassifFocC)
    mdlfc = load(PA.ClassifFocC); mdlfc=mdlfc.mdl; %KNN classifier for focal child
else
    mdlfc=[];
end
if ~isempty(PA.ClassifFocT)
    mdlft = load(PA.ClassifFocT); mdlft=mdlft.mdl; %KNN classifier for focal teacher
else
    mdlft=[];
end

%%%%% Identify speakers
for ij = 1:size(Vad,1) %for each utterance
    tio = Vad(ij,1);
    tif = Vad(ij,2);

    Inu = find(Vad(:,2) >= tio & Vad(:,1) <= tif); %get utterances in the frame (overlapping with current utterance)
    Tru = []; %tracks in frame
    Spu=[]; %speakers in frame
    IEu = string; %ineligible speakers
    Linu = length(Inu); %number of overlapping utterances in the frame
    for ii = 1:Linu %for each utterance in the frame
        Inuii = Inu(ii); %utterance index in Vad
        if strcmp(SP(Inuii),"") %utterance is unnassigned
            Inru = find(Tru==Vad(Inuii,3));
            if ~isempty(Inru)
                SP(Inuii) = Spu(Inru(1));
            else
                tiio = Vad(Inuii,1);
                tiif = Vad(Inuii,2);

                aus = audioread(auout,floor(max(1,[tiio tiif]*Fs)));
                results = classify_ideas(aus,iv,mdlg,mdlfc,mdlft);  %mdlg,mdlf (mdlf only for PK)
                results = results(~ismember(results.Label,categorical(IEu)),:); %only eligible scores
                SP(Inuii) = string(results.Label(1)); %selecy the one with max score
                RES{Inuii} = results;
            end
        end
    end
    if ~contains(SP(Inuii),'00') %if not generic, include it in ineligible speakers
        IEu = union(IEu,SP(Inuii));
    end
    Tru = [Tru;Vad(Inuii,3)];
    Spu = [Spu;SP(Inuii)];
end

