function y = gentempau(MD,auout,auin,PA)
%%%%%% Generates temporary audio
Fs = PA.Fs; %16e3;
stereo = PA.stereo;
acollar = PA.acollar*Fs; %collar around vad
info = audioinfo(auin); 
fsa = info.SampleRate;
[P,Q] = rat(Fs/fsa);
au=[];

for ik = 1:size(MD.TAw,1) %for each segment
    range = min(info.TotalSamples,max(1,round([MD.TAw(ik,1),MD.TAw(ik,2)]*fsa)));
    %afr = dsp.AudioFileReader(auin,'ReadRange',range,'SamplesPerFrame',min(Win*fsa,diff(range)+1));
    %while ~isDone(afr)
        %aui = afr();
        aui = audioread(auin,range);
        if stereo == 0
            aui = mean(aui,2);
        end
        aui = resample(aui, P, Q); %mono and downsample to Fs
        %%%%% Silence acollar
        if ik == 1 %first segment
            aui(end-round(acollar/2):end)=0;
        elseif ik == size(MD.TAw,1)  %last segment
            aui(1:round(acollar/2))=0;
        else
            aui(end-round(acollar/2):end)=0;
            aui(1:round(acollar/2))=0;
        end
        au = [au;aui];
        %afw(aui);
    %end
    %release(afr);
end
%release(afw);
audiowrite(auout,au,Fs)

y=[];