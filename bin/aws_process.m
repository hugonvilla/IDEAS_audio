function pflag = aws_process(jfile)
%%%% script to process AWS output
[~,wname] = fileparts(jfile);
PA = parameters();
awflag=PA.awflag;
%%%% Decode name
Jname = split(wname,'_');


if strcmp(Jname{end},'fail')
    msg = ['AWS work ' erase(wname,'_fail') ' has failed. Check error log']; 
    disp(msg)
    delete(jfile); 
    aufile = strrep(erase(jfile,'_fail'),'json','wav');
    delete(aufile)
    pflag = 0;
else
    TFname = fullfile(pwd,'temp',[wname '.mat']); %temporal descriptors
    try
        TF = load(TFname); TF=TF.TF;
    catch
        msg = ['Temporal descriptor not found: ', TFname];
        disp(msg);
        pflag = 0;
        return
    end
    if awflag == 1
        [AW,AWC] = WTProc(jfile,TF); %whisper
    else
        [AW,AWC] = ATProc(jfile,TF); %aws
    end
    AWP = audio_process(AW,TF); %merge AWS transcript with segmentation
    AW.wname = repmat(string(wname),size(AW,1),1);%append work name
    AWC.wname = repmat(string(wname),size(AWC,1),1);
    TF.AWP=AWP;
    TF.AW=AW;
    TF.AWC=AWC;
    
    save(TFname,'TF');
    pflag = 1;
    movefile(jfile,fullfile(pwd,'temp',[wname '.json']))
end






