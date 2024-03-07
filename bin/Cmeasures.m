function Y = Cmeasures(GTCi,fid)
PA = parameters();
mct = PA.mct;
mdt = PA.mdt;
Vname = {'CT','SD'};
%GTCi(GTCi.spk_type=="S00",:)=[];
Spki = categorical(GTCi.spk_type);
Uspki = unique(Spki);
Exp = setdiff(Uspki,fid); %other speakers
Spki = mergecats(Spki,string(Exp),"NN");

Sp = [categorical("NN");fid];

%% Convo count
Cn=1;
for k = 2:size(Spki,1) %for each utterance in the convo
    if Spki(k) ~= Spki(k-1) && GTCi.start_a(k)-GTCi.end_a(k-1) > mct %if there is a change in speaker % if the change happens before mct seconds after the previous ut
        Cn(k) = Cn(k-1)+1;
    else
        Cn(k) = Cn(k-1);
    end
end
%%% Conversational Turn Labeling
Ct=0; %initialize turn count (adult,child,peer)
if ~isempty(Spki)
    for i = 1:max(Cn) %for each convo
        idi = find(Cn==i);
        GTCic = GTCi(idi,:);
        Spkic = Spki(idi);
        Ctc=[0 0];
        for k = 2:size(Spkic,1) %for each utterance in the convo
            if Spkic(k) ~= Spkic(k-1) %if there is a change in speaker
                if GTCic.end_a(k) - GTCic.start_a(k) > mdt & GTCic.end_a(k-1) - GTCic.start_a(k-1) > mdt %if the duration of the utterances accros the speaker change is at least mdt seconds
                    Ctc(find(Sp==Spkic(k))) = Ctc(find(Sp==Spkic(k)))+1; %increase counter of new speaker
                end
            end
        end
        Ct=Ct+min(Ctc);
    end
end

%% Duration
GTs = GTCi(GTCi.spk_type == string(fid),:);
Dur = sum(GTs.end_a-GTs.start_a);

Y = table(Ct,Dur,'VariableNames',Vname);

end