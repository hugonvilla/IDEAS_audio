function eflag = run_IDEAS(varargin)

%%%%% Data processing with IDEAS
tic
%%%%%%%%%%% Function arguments, in order:
cflag = 0; %0 detele temp, 1 do not delete
Ilist = varargin{1}; %path to input data list file

if length(varargin)>=2
    cflag = varargin{2};
end

addpath(genpath(pwd))

PA = parameters();
awflag = PA.awflag;

if awflag == 0
    disp('Data will not be transcribed.')
end

Mdur = 12*60*60; %max duration AWS

delete([fullfile(pwd,'bin','aws') filesep '*.wav']); %%%%% delete files in aws
delete([fullfile(pwd,'bin','aws') filesep '*.json']); %%%%% delete files in aws
delete([fullfile(pwd,'temp') filesep '*']); %%%%% delete files in temp


%% Read and Process Data 
opts = delimitedTextImportOptions("NumVariables", 2);
opts.Delimiter = ",";
Rdata = readtable(Ilist,opts);

eflag=0; %initialize exit flag
for i = 1:size(Rdata,1) %for each file
    Fopath = Rdata{i,1}{1}; %video file path
    if ~isempty(Rdata{i,2})
        Tpath = Rdata{i,2}{1}; %oracle timestamp 
    else
        Tpath=[];
    end
    TF = audio_diarize(Fopath,Tpath); %TF contains the onset of audio segments containing speech
end
disp(['Data pre-processing has concluded.'])

toc

%% Send and process transcript with AWS

if awflag~=0
    Kaws=0;
    if awflag == 1
        Kaws = whisper_send(); %whisper
    else
        Kaws = aws_send(); %aws
    end

    %%%%%% Wait for AWS to finish
    now1 = tic;
    kproc=0; kfail=0;
    if Kaws > 0 %if there are aws jobs to process
        disp(['Works awaiting processing: ' num2str(Kaws)])
        while true
            if toc(now1) > Mdur 
                error('AWS processing is taking too long. Ending process')
            end
            disp('Waiting for Transcript files...')
            Jdata = dir([fullfile(pwd,'bin','aws') '/*.json']);
            Jdata(contains({Jdata.name},'._')) = []; %delete ghost files present in windows
            if ~isempty(Jdata) %if there are aws files to process
                disp(['Processing Transcript file number ' num2str(kproc+kfail+1)])
                jfile = fullfile(Jdata(1).folder,Jdata(1).name);
                pflag = aws_process(jfile); %process first available aws output
                if pflag == 1
                    kproc = kproc+1; %increase counter of success
                else
                    kfail = kfail+1;
                    eflag=1;
                end
            elseif kproc+kfail >= Kaws %check if all AWS works are done
                break
            end
            pause(10)
        end
    end

else
    disp('Data will not be sent to AWS')
end
%% Produce final output
disp('Processing transcripts')
Temp = fullfile(pwd,'temp'); %temp folder path
Tdata = dir([Temp filesep '*.mat']);
Tdata(cellfun(@(x) ismember(x(1),{'.','_','~'}), {Tdata.name}.'),:)=[];
Rdir = fullfile(pwd,'output'); %output folder
for i = 1:size(Tdata,1) %for each file to process
    omname = fullfile(Temp,Tdata(i).name);
    TF=load(omname); TF=TF.TF; %load temp file
    [LM,AW,LMB] = metrics_calc(TF); %metrics. By default, they are saved in csv files
    writetable(AW,fullfile(Rdir,[erase(Tdata(i).name,'.mat') '_diar.csv'])); %write diarization output
    writetable(LM,fullfile(Rdir,[erase(Tdata(i).name,'.mat') '_out.csv'])); %write output measures
    writetable(LMB,fullfile(Rdir,[erase(Tdata(i).name,'.mat') '_batchout.csv'])); %write output measures
    movefile(omname,fullfile(Rdir,Tdata(i).name))
    movefile(fullfile(Temp,strrep(Tdata(i).name,'.mat','.json')),fullfile(Rdir,strrep(Tdata(i).name,'.mat','.json')));
end

%%%%%% Cleanup
if cflag ==0
    delete([fullfile(pwd,'bin','aws') filesep '*.wav']); %%%%% delete files in aws
    delete([fullfile(pwd,'bin','aws') filesep '*.json']); %%%%% delete files in aws
    delete([fullfile(pwd,'temp') filesep '*']); %%%%% delete files in temp
end

if eflag==1
    error(['Some folders contain errors'])
else
    disp(['IDEAS ran successfully'])
end

rmpath(genpath(pwd))


