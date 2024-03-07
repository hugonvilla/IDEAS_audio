function kaws = whisper_send()

addpath(fullfile(pwd,'bin'))   

PA = parameters();
%% Retrieve work data, generate audio files and send work to AWS
Temp = fullfile(pwd,'temp'); %temp folder path
Tdata = dir([Temp '/*.mat']);
Tdata(cellfun(@(x) ismember(x(1),{'.','_','~'}), {Tdata.name}.'),:)=[];
apath = fullfile(pwd,'bin','aws'); %folder path to auxiliary aws folder

kaws = 0; %work count sent to aws
for jj = 1:size(Tdata,1) %for each temp file 
    omname = fullfile(Temp,Tdata(jj).name);
    TF=load(omname); TF=TF.TF; %load temp file
    [~,WN] = fileparts(omname); %work name
    auin = fullfile(Temp,[WN '.wav']); %audio file name
    auname = fullfile(apath,[WN,'.wav']); 
    
    kaws = kaws+1; %count of works that need processing
    if ~exist(auname,'file') %if no audio file, generate it to process it
        y = gentempau(TF,auname,auin,PA); %write audio files
    end
    if ~exist(fullfile(Temp,[WN,'.json']),'file') %if json file not present in the output folder
        if  ~exist(fullfile(apath,[WN,'.json']),'file')  %if json file not in the processing folder
            if isunix
                system(['cd bin/aws; python whispertrans.py ' WN]); %send file to whisper, serial execution
            elseif ispc
                system(['cd bin\aws & python whispertrans.py ' WN]);
            end

        end
    else
        disp(['Whisper output found for work ' WN ' . Data will not be sent to Whisper'])
        copyfile(fullfile(Temp,[WN,'.json']),apath); %copy json file to input folder
    end 
end