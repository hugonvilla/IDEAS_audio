function [AWn] = audio_process(AW,MD)
rng(4)
%%%%%% Post-process AWS Transcribe results
%%%% load Metadata

TW = MD.TW; %segment time in temp time
TA = MD.TA; %segment time in audio time
AWR = MD.AWR;
PA=parameters();
Tmin = PA.Tmin;  %minimum duration in seconds

%% Post process AWS

Nutt =size(AW,1);
AWn = [];
for i = 1:Nutt %for each transcribed utterance

    Toi = AW.start(i); %initial time in temp audio time
    Tfi = AW.end(i);
    %Inx = find(TW(:,2) >= Toi & TW(:,1) <= Tfi); %find which segment this utterance belongs to
    Inx = find(TW(:,1) <= Toi & TW(:,2) >= Tfi); %find which segment this utterance belongs to

    for jj = 1:length(Inx) %for each segment encompassing the utterance (in theory only one). PROBLEM: SOME UTTERANCES HAVE MULTIPLE Inx.
        towj = max(Toi,TW(Inx(jj),1)); %subsegment initial time in temp time
        tfwj = min(Tfi,TW(Inx(jj),2));
        Spkj = AWR.spk_type(Inx(jj));

        AWkn = AWR(Inx(jj),:);
        AWkn.start_a = TA(Inx(jj),1) + (towj-TW(Inx(jj),1)); %subutterance initial time in original audio time
        AWkn.end_a = TA(Inx(jj),1) + (tfwj-TW(Inx(jj),1));
        AWkn.start_w = towj; %subsegment initial time in temp time
        AWkn.end_w = tfwj;

        str = AW.trans(i); % join(AWC.words(Iwx));
        if ismissing(str)
            str = "xxx"; %assumes that since Pyannote recognized speech, there must be at least a word here. This might not be valid in baby talk
        end
        Cjj = AW.conf(i); %mean(AWC.conf(Iwx));
        AWkn.trans = str;
        AWkn.conf = Cjj;

        ostr = AW.otrans(i);
        if ismissing(ostr)
            ostr = "xxx"; %assumes that since Pyannote recognized speech, there must be at least a word here. This might not be valid in baby talk
        end
        AWkn.otrans = ostr;

        AWn = [AWn;AWkn];
    end
end
AWn(AWn.end_a-AWn.start_a<Tmin,:)=[]; %delete short utterances
if ~isempty(AWn)
    AWn = sortrows(AWn,'start_a'); %sort chronologically
end



