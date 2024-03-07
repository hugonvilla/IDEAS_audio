function results = classify_ideas(aus,iv,mdlg,mdlfc,mdlft)


%%%%%%% Generic KNN classifiers
xaus = ivector(iv,aus)';
[Spkg,scoreg] = predict(mdlg,xaus); %generic teacher (T00) vs peer (S00)
Label = mdlg.ClassNames;
Score = scoreg';

if ~isempty(mdlfc) && Spkg == "S00" && contains(Aname,'S')    %if child utterance
    [Spkfc,scorefc] = predict(mdlfc,xaus);
    Label = mdlfc.ClassNames;
    Label = renamecats(Label,"S99",Aname); %rename focal
    Score = scorefc';
elseif ~isempty(mdlft) && Spkg == "T00" && contains(Aname,'T') %focal vs generic teacher
    [Spkft,scoreft] = predict(mdlft,xaus);
    Label = mdlft.ClassNames;
    Label = renamecats(Label,"T99",Aname); %rename focal
    Score = scoreft';
end

results = table(Label,Score);
results = sortrows(results,"Score","descend");


    


                    