function [AW,AWC] = WTProc(AUjson,MD)

    PA = parameters();
    useg = PA.useg; %utterance segmentation
    %Diar = PA.Diar;
%     if strcmp(Diar,'oracle')
%         useg = 0; %by default, oracle does not require segmentation
%     end
    %% Parse Json and append transcription to speaker_labels field
    
    fid = fopen(AUjson,'r');
    raw = fread(fid);str = char(raw');fclose(fid);
    valAU=jsondecode(str);clear raw str

    AWnames = {'spk','start','end','trans','conf','ind','otrans'};
    AWCnames = {'words','start','end','conf'};
    WTnames = {'word','start','end','probability'};
    AWe = table(nan, nan,nan,"",nan,nan,"",'VariableNames',AWnames);
    AWCe = table("",nan,nan,nan,'VariableNames',AWCnames);
    WT=[];
    for i=1:size(valAU.segments,1) %for each utterance
        if i==1
            WT = struct2table(valAU.segments(i).words,"AsArray",true);
            WT.Properties.VariableNames=WTnames;
            if ~iscell(WT.word)
                WT.word=cell(WT.word);
            end
        else
            if ~isempty(valAU.segments(i).words)
                wti = struct2table(valAU.segments(i).words,"AsArray",true);
                wti.Properties.VariableNames=WTnames;
                if ~iscell(wti)
                    wti.word=cell(wti.word);
                end
                WT=[WT;wti];
            end
        end
    end
    if isempty(WT) %if no words detected
        AW=AWe;
        AWC=AWCe;
        return
    end
    WT.word=strtrim(WT.word); %delete leading space
    %Pvc = find(cellfun(@(x) any(x),isstrprop(WT.word,'punct'))); %indices of words with punctuations
    Pvc = find(cellfun(@(x) contains(x,{'.',',','?',':',';','!'}),WT.word));
    
    if ~isempty(Pvc) %if there is punctuation
        for i=1:size(Pvc,1) %for each word with punc
            if i==1
                WTT=WT(1:Pvc(i),:);
            else
                WTT=[WTT;WT(Pvc(i-1)+1:Pvc(i),:)];
            end
            WTT.word(end)=erasePunctuation(WTT.word(end));
            woi = WT.word{Pvc(i)};
            pwoi=woi(end);
            WTT(end+1,:) = WTT(end,:);
            WTT.word{end}=pwoi;
        end
    else
        WTT=WT;
    end
    To=WTT.start;
    Tf=WTT.end;

    segments = struct;
    if isempty(MD)
        Am = struct2cell(valAU.results.speaker_labels.segments); 
        Tm = [str2double(Am(1,:));str2double(Am(3,:))];
    else
        %Tm = MD.TW';
        Tm = MD.TWo'; %un-collared
    end
    indTra=[]; %repeated word index
    frep = 0; %if == 1, allows repeated words
    for i = 1:size(Tm,2) %for each segment
        %indTr = find(To >= Tm(1,i) & Tf <= Tm(2,i)); %words in segment indices. narrow, less repetition
        indTr = find(To <= Tm(2,i) & Tf >= Tm(1,i)); %wider,more repetition
        k=0;
        if ~isempty(indTr)
            for j =1:length(indTr) %for each word
                if ~ismember(indTr(j),indTra) || frep == 1 %if it's not a repeated word
                    k=k+1;
                    indTra = [indTra;indTr(j)]; %index to avoid repetition
                    str = string(WTT.word(indTr(j)));
                    if j==1 && all(isstrprop(str,'punct'))==1 %if first element is punctuation from previous sentence, do not include
                        k = 0; %restart index
                    else
                        segments(i).content(k).words = str; %transcription;
                        segments(i).content(k).start_time = To(indTr(j));
                        segments(i).content(k).end_time = Tf(indTr(j));
                        segments(i).content(k).confidence = WTT.probability(indTr(j));
                    end
                else
                    segments(i).content(1).words = ""; %transcription;
                    segments(i).content(1).start_time = Tm(1,i);
                    segments(i).content(1).end_time = Tm(2,i);
                    segments(i).content(1).confidence = 0;
                end
            end
        else
            segments(i).content(1).words = ""; %transcription;
            segments(i).content(1).start_time = Tm(1,i);
            segments(i).content(1).end_time = Tm(2,i);
            segments(i).content(1).confidence = 0;
        end
    end
    clear HT WCto WCtf WCw
    Ams = squeeze(struct2cell(segments)); 
    WCto = []; WCtf=[]; WCw=[]; WCco=[];
    k=1;
    for i = 1:size(Ams,1) %%%% This re-segments the segments using punctuation
        try
            Wi = {Ams{i}.words}.';
        catch
            Wi=[]; %if no words in segment, fill it below
        end
        
        
        if ~isempty(Wi) %if there are words
            Tok = 1; %initial start time index
            %for j=size(Wi,1) %no utterance segmentation
            for j=1:size(Wi,1) %utterance segmentation (for each word)
                if useg == 0
                    j = size(Wi,1); %no utterance segmentation
                end
                if sum(contains(Wi{j},[".","?",";",":","!"]))>=1 || j == size(Wi,1) %if breaking punct or last item

                    HT{k,1} = 0; %str2double(Ams{2,i}(5:end))+1; %speaker string to number, +1 to account for zeroth person
                    %HT{i,2} = max([Ams{i}(Tok).start_time].',Tm(1,i)); %initial time
                    %HT{i,3} = min([Ams{i}(j).end_time].',Tm(2,i));

                    if Tok == 1
                        HT{k,2} = Tm(1,i); %initial time
                    else
                        HT{k,2} = min([Ams{i}(Tok).start_time].',HT{k-1,3}); %initial time
                    end

                    if j == size(Wi,1) %if last item
                        HT{k,3} = Tm(2,i);
                    else
                        HT{k,3} = [Ams{i}(j).end_time].';
                    end

                    h = string(Wi(Tok:j));
                    ho = h;
                    h = lower(h);
                    h=strrep(h,'''s',' is');
                    h=strrep(h,'''re',' are');
                    h=strrep(h,'''m',' am');
                    h=strrep(h,'''ll',' will');
                    h=strrep(h,'can''t',' not');
                    h=strrep(h,'n''t',' not'); %problem with can't - ca not
                    h=strrep(h,'gonna','going to'); 
                    h=strrep(h,'wanna','want to'); 
                    h=strrep(h,'gotta','got to'); 
                    h = erasePunctuation(h); 
                    hs = h;
                    hs(h=="") = [];%utterance's words. Delete punc
                    HT{k,4} = join(hs); %segment scalar string
                    Conf = [Ams{i}(Tok:j).confidence].';
                    Conf(h=="")=[]; %delete punctuation confidence
                    HT{k,5} = mean(Conf); %mean transcript confidence
                    HT{k,6} = i; %index tracker
                    WCtoi = [Ams{i}(Tok:j).start_time].';
                    WCtoi(h=="")=[];
                    WCto = [WCto;WCtoi];
                    WCtfi = [Ams{i}(Tok:j).end_time].';
                    WCtfi(h=="")=[];
                    WCtf = [WCtf;WCtfi];
                    if ~iscolumn(hs)
                        hs = hs';
                    end
                    WCw = [WCw;hs];
                    WCco = [WCco;Conf];
                    HT{k,7} = join(ho); %original transcript
                    k=k+1;
                    Tok = j+1; %move to next
                end
                if useg == 0
                    break
                end
            end
        else
            HT{i,1} = 0;
            HT{i,2} = Tm(1,i);
            HT{i,3} = Tm(2,i);
            HT{i,4} = "";
            HT{i,5} = 0;
            HT{i,6} = i;
            HT{i,7} = "";
        end
    end
    HTt = cell2table(HT);
    %HTt = rmmissing(HTt,'DataVariables','HT4'); %delete non-transcirbed sentences (***)
    AW = HTt;
    AW.Properties.VariableNames = AWnames;
    WC = array2table(zeros(size(WCto,1),4),'VariableNames',AWCnames);  
    WC.start = WCto; WC.end = WCtf; WC.words=WCw; WC.conf = WCco;
    AWC = WC;
end