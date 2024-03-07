function [TF] = audio_diarize(aname,Tpath)
apath = fullfile(pwd,'bin','pyannote');
ydat = fullfile(apath,'temp','database.yml');
[Fpath,wname] = fileparts(aname);
rng(4)
%% Read parameters
PA = parameters();
Fs = PA.Fs;
Tmin = PA.Tmin;
Lon = PA.Lon;
Segmodel = PA.Segmodel;

auout = fullfile(apath,'temp','temp.wav');  
TF=struct;
%% Read and write
try
    [au,fs] = audioread(aname);
catch
    awname = fullfile(pwd,'data',[wname '.wav']);
    [fso,fcmdout]=system(['ffmpeg -i "' aname '" -vn "' awname '" > /dev/null']);
    [au,fs] = audioread(awname);
    delete(awname)
end

[P,Q] = rat(Fs/fs);
au = mean(au,2);
au = resample(au,P,Q);
audiowrite(auout,au,Fs);
copyfile(auout,fullfile(pwd,'temp',[wname '.wav']))

%% Segmentation
Nspk = 3;
if ~isempty(Tpath) 
    if ~strcmp(PA.Diar,'oracle') %override to oraclepy
        PA.Diar = 'oraclepy';
        Segmodel='steps2.yaml';
    end
end

alice_path = fullfile(apath,'ALICE');
so=[];
if isunix
    if strcmp(PA.Diar,'alice')
        setenv('PATH',['/Users/gonzalezvillasanti.1/anaconda3/envs/ALICE/bin' ':/usr/bin:/bin:/usr/sbin:/sbin']); %replace with proper path in each computer
        [so,cmdout] = system(['cd ' alice_path '; ./run_ALICE.sh ' auout ' > /dev/null']);
    elseif strcmp(PA.Diar,'ideas')
        [so,cmdout] = system(['cd bin/pyannote; export PYANNOTE_DATABASE_CONFIG="' ydat '"; python seginfer.py "' auout '" ' Segmodel ' >/dev/null']); %send file to AWS
    elseif strcmp(PA.Diar,'pyannote') || strcmp(PA.Diar,'oraclepy')
        [so,cmdout] = system(['cd bin/pyannote; export PYANNOTE_DATABASE_CONFIG="' ydat '" ; python diarinfer.py "' auout '" ' Segmodel ' ' num2str(Nspk) ' >/dev/null']); %send file to AWS
    end
elseif ispc
    [so,cmdout] = system(['cd bin\pyannote & set PYANNOTE_DATABASE_CONFIG=' ydat ' & python seginfer.py ' auout ' ' Segmodel ' >nul2 >nul']);
end

if so ~= 0
    msg = ['ERROR when processing audio with Pyannote. Check log file in pyannote folder.'];
    disp(msg)
    Elog = string(cmdout);
    writematrix( Elog , fullfile(apath,'Elog.txt'));
    return
end

info = audioinfo(auout);
totsam = info.TotalSamples;
fsa = info.SampleRate;
Len = ceil(info.Duration*fsa); 

if strcmp(PA.Diar,'alice')
    opts = delimitedTextImportOptions("NumVariables", 10);
    opts.Delimiter = " ";
    opts.VariableTypes = ["categorical", "categorical", "double", "double", "double", "categorical", "categorical", "string", "categorical", "categorical"];
    if exist(fullfile(alice_path,'diarization_output.rttm'))~=0
        movefile(fullfile(alice_path,'diarization_output.rttm'),fullfile(alice_path,'diarization_output.txt'))
        Vtc = readtable(fullfile(alice_path,'diarization_output.txt'),opts);
        Del = find(ismember(Vtc{:,8},{'SPEECH'}));
        Spe = Vtc(Del,:);
        idx = [[Spe{:,4}] [Spe{:,4}]+[Spe{:,5}]]; %Vad

        Vtc(Del,:)=[];
        Vad = [[Vtc{:,4}] [Vtc{:,4}]+[Vtc{:,5}]];
        SP = [Vtc{:,8}]; %speakers 
        SP(contains(SP,{'CHI'})) = "S00"; %"S00";
        if contains(Aname,'S') 
            SP(contains(SP,{'KCHI'})) = Aname;
            SP(contains(SP,{'FEM','MAL'})) = "T00"; % "T00";
        else
            SP(contains(SP,{'KCHI'})) = "S00";
            SP(contains(SP,{'FEM','MAL'})) = "T99"; % "T00";
        end
        
        %constrain Vad to idx
        dvad = [];
        for jj = 1:size(Vad,1)
            idjj = find(idx(:,1) <= Vad(jj,2) & idx(:,2) >= Vad(jj,1));
            ovlj = [max(idx(idjj,1),Vad(jj,1)) min(idx(idjj,2),Vad(jj,2))];
            [vol,idjs] = max(ovlj(:,2)-ovlj(:,1)); %biggest overlap
            if vol > 0 %if there exists overlap
                Vad(jj,:) = ovlj(idjs,:);
            else
                dvad = [dvad;jj]; %delete vad entry
            end
        end
        Vad(dvad,:)=[];
        SP(dvad)=[];

        RES = cell(1,size(SP,1)); %empty scores
        delete(fullfile(alice_path,'diarization_output.txt'));
    else
        Vad=[];
        idx=[];
    end
elseif strcmp(PA.Diar,'ideas')

    Acv = load(fullfile(apath,'vad.mat')); Acv=double(Acv.mydata);
    na = size(Acv,1); %number of tracks
    Scv = sort(Acv,1,'descend')'; Acv=Acv';
    Acv(:,na+1)=Scv(:,1); %vad
    if size(Scv,2)>1
        Acv(:,na+2)=Scv(:,2); %osc
    end
    
    for i=1:size(Acv,2)
        Vadi=[];
        Vadi = binmask2sigroi((Acv(:,i)>Lon)); %0.45 for steps, 0.6 for PK
        Vadi = floor((Vadi-1)*(totsam-1)/(size(Scv,1)-1)+1);
        Vadi = mergesigroi(Vadi,round(Tmin*Fs));
        Vadi = removesigroi(Vadi,round(Tmin*Fs));
        Vadi = Vadi./Fs; 
        Vada{i} = [Vadi repmat(i,size(Vadi,1),1)]; %append track number
    end
    Vad = vertcat(Vada{1:na});
    Vad = sortrows(Vad,1); %sort in chronological order
    delete(fullfile(apath,'vad.mat'))
    idx = Vada{na+1}; 

elseif strcmp(PA.Diar,'oracle')

    %%%%% ELAN transcripts
    TEL = ELAN_process(Tpath,"S99");
    TEL.spkid = string(TEL.spkid);
    TEL.spkid(ismissing(TEL.spkid)) = "S00";
    Uspk = unique(TEL.spkid);
    SP=strings; Vad=[];
    %%%%% Oraclize human transcript
    for ii = 1:numel(Uspk) %for each speaker
        TELi=TEL(TEL.spkid==Uspk(ii),:);
        Vadi=[TELi.start_a TELi.end_a];
        Vadi=[floor(Vadi(:,1)*Fs+1) ceil(Vadi(:,2)*Fs+1)];
        Vadi=mergesigroi(Vadi,Tmin*Fs); %MERGE close utterances for each speaker
        Vadi=max(0,(Vadi-1)/Fs);
        SP=[SP;repmat(Uspk(ii),size(Vadi,1),1)];
        Vad=[Vad;Vadi];
    end
    SP(1,:)=[];
    [Vad,ixn]=sort(Vad,1);
    SP=SP(ixn(:,1));
    RES = cell(1,size(SP,1)); %empty scores

elseif strcmp(PA.Diar,'oraclepy') %oracle with auto diar

    %%%%% ELAN transcripts
    TEL = ELAN_process(Tpath,"S99");
    TEL.spkid = string(TEL.spkid);
    TEL.spkid(ismissing(TEL.spkid)) = "S00";

    Uspk = unique(TEL.spkid); %speaker IDs in oracle
    SPn=strings; Vadn=[];
    %%%%% Oraclize with coarse timestamp
    for ii = 1:numel(Uspk) %for each speaker
        TELi=TEL(TEL.spkid==Uspk(ii),:);
        Vadi=[TELi.start_a TELi.end_a];
        Vadi=[floor(Vadi(:,1)*Fs+1) ceil(Vadi(:,2)*Fs+1)];
        Vadi=mergesigroi(Vadi,2.9*Fs); %MERGE close utterances for each speaker up to 3 seconds
        Vadi=max(0,(Vadi-1)/Fs);
        SPn=[SPn;repmat(Uspk(ii),size(Vadi,1),1)];
        Vadn=[Vadn;Vadi];
    end
    SPn(1,:)=[];
    [Vadn,ixn]=sort(Vadn,1);
    SPn=SPn(ixn(:,1));

    %%%%%% PYANNOTE PART
    opts = delimitedTextImportOptions("NumVariables", 10);
    opts.Delimiter = " ";
    opts.VariableTypes = ["categorical", "categorical", "double", "double", "double", "categorical", "categorical", "categorical", "categorical", "categorical"];
    if exist(fullfile(apath,'output.rttm'))~=0
        movefile(fullfile(apath,'output.rttm'),fullfile(apath,'output.txt'))
        Vtc = readtable(fullfile(apath,'output.txt'),opts);
        idx = [[Vtc{:,4}] [Vtc{:,4}]+[Vtc{:,5}]]; %Vad
        SPx = [Vtc{:,8}]; %speakers 
        SPnp=grp2idx(SPx);
        Vadpy = [idx SPnp];
    end

    %%%%% Map oracle speakers to pyannote
    SPM = map_oracle_pyan(Vadpy,Vadn,SPn,Fs,Len);

    %%%% Procedure unique to STEPS, since auto-diar is good for adult talk
    iad = find(contains(Uspk,'T'));
    Vadad = Vadpy(Vadpy(:,3)==SPM.py(iad),:); %take all pyannote adult talk
    SP=repmat("T00",size(Vadad,1),1);
    USosn = setdiff(Uspk,"T00");
    Vadadn = [floor(Vadad(:,1)*Fs+1) ceil(Vadad(:,2)*Fs+1)];
    mvadad = sigroi2binmask(Vadadn,Len); %mask of adult talk
    Vad = Vadad(:,1:2);
    for i = 1:numel(USosn) %for each non-adult speaker
        TELi = TEL(TEL.spkid == USosn(i),:);
        Vadi=[TELi.start_a TELi.end_a];
        Vadi=[floor(Vadi(:,1)*Fs+1) ceil(Vadi(:,2)*Fs+1)];
        mij = sigroi2binmask(Vadi,Len);
        mij = max(mij-mvadad,0); %only leave speech that does not overlap with py-adult
        Vij = binmask2sigroi(mij);
        Vij = mergesigroi(Vij,round(Tmin*Fs));
        Vij = removesigroi(Vij,round(Tmin*Fs));
        Vij=max(0,(Vij-1)/Fs);
        Vad = [Vad; Vij];
        SP = [SP;repmat(string(USosn(i)),size(Vij,1),1)];
    end
    [Vad,ixn]=sort(Vad,1);
    SP=SP(ixn(:,1));
    RES = cell(1,size(SP,1)); %empty scores

end

%%% Extend idx and Vad
Vado = Vad; %save original Vad for classification;

collar = round(PA.collar*fsa); %collar around utterances
acollar = round(PA.acollar*fsa); %collar around idx

Vadi = min(round(Vad(:,1:2)*fsa+1),info.TotalSamples);
Vadi = min(extendsigroi(Vadi,collar,collar),info.TotalSamples);
Vadin = max(0,(Vadi-1)/fsa);
Vad(:,1:2) = Vadin;

idxi = mergesigroi(Vadi,acollar);
idxin = min(extendsigroi(idxi,round(acollar/2),round(acollar/2)),info.TotalSamples);
idx = max(0,(idxin-1)/fsa);

%% Export audio
varname = {'spk_type','start_w','end_w','start_a','end_a','wname','scores','trans','otrans'};

if ~isempty(idx) %if there is VAD detection
    kk=0; %valid segment count
    TAw = nan(size(idx,1),1);
    TA=nan(size(Vad,1),1);
    TW=nan(size(Vad,1),1);TWo=nan(size(Vad,1),1);
    Tos = 0; 
    for i = 1:size(idx,1) %for each vad segment
        to = idx(i,1); %segment initial time in temp audio time (taok = 0)
        tf = idx(i,2); 
        TAw(i,1) = to; %segment initial time in original audio time (seconds)
        TAw(i,2) = tf;
        
        %%%%%%% fInd utterances contained in vad segment
        Inu = find(Vad(:,1) >= to & Vad(:,2) <= tf);
        for ki = 1:length(Inu) %for each utterance in the segment
            kk=kk+1;
            Ini = Inu(ki);
            toi = max(Vad(Ini,1),to);
            tfi = min(Vad(Ini,2),tf);
            toio = max(Vado(Ini,1),to); %un-collared utterance
            tfio = min(Vado(Ini,2),tf);
            
            TW(kk,1) = Tos + (toi-to); %utterance initial time in work time
            TW(kk,2) = Tos + (tfi-to); %utterance final time in work time
            TWo(kk,1) = Tos + (toio-to); %un-collared utterance initial time in work time
            TWo(kk,2) = Tos + (tfio-to); %un-collared utterance final time in work time
            TA(kk,1) = toi; %utterance initial in audio time
            TA(kk,2) = tfi; %utterance initial in audio time
        end
        Tos = Tos+ (tf-to);
    end
    if strcmp(PA.Diar,'ideas')
        [SP,RES] = spk_identification(auout,Vado);
    end
    
    TF.AWR = table(SP,TW(:,1),TW(:,2),TA(:,1),TA(:,2),repmat(string(wname),size(TA,1),1),RES',repmat("",size(TA,1),1),repmat("",size(TA,1),1),'VariableNames',varname);
    TF.AWP=TF.AWR; %preallocate
    TF.AWC=[];
    TF.TAw=TAw;
    TF.TA=TA;
    TF.TW=TW;
    TF.TWo=TWo;
    TF.TD = info.Duration;

else
    TF.AWR=[];
    TF.AWP=[];
    TF.AWC=[];
    TF.TAw=[];
    TF.TA=[];
    TF.TW=[];
    TF.TWo=[];
    TF.TD = [];
end

save(fullfile(pwd,'temp',[wname,'.mat']),'TF'); %save auxiliar file
delete(auout)






