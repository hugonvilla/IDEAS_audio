function PA = parameters()

%%%%% General audio
PA.Fs = 16e3; %audio sample rate. Default: 16e3;
PA.stereo = 0; %stereo flag. Default: off (0).
PA.collar = 0.1; %collar around detected speech in seconds
PA.acollar = 1; %zero-collar around detected speen in seconds for audio generation

%%%%% Transcript
PA.awflag = 1; %0 for no transcription, 1 for whisper, 2 for aws

%%%%% Tokenizer
PA.Tokenizer = 'spacy'; %Tokenizer engine. Options: 'spacy', 'matlab'

%%%%% Speaker diarization
PA.Diar = 'ideas'; %diarizer tool. Options: 'alice', 'ideas', 'oracle', 'oraclepy', 'pyannote'
PA.useg = 1; %uterance segmentation in ATProc. 1 for true. By default, useg is false when oracle
PA.Tconf = 0; %0.3 minimum mean utterance confidence in AWS transcript for teacher
PA.Tmin = 0.3; %0.3 minimum time in AWS transcript for teacher
PA.Cconf = 0; %0.3 minimum mean utterance confidence in AWS transcript for child
PA.Cmin = 0.3; %0.3 minimum time in AWS transcript for child
PA.Lon = 0.5; %on threshold: %0.6 pk, 0.5 steps, 0.6 peers. 0.5 for LENA
PA.mct = 5; %max time between utts within a conversation, for Cmeasures
PA.mdt = 0; %min utt time to consider a speaker change, for Cmeasures


PA.Segmodel = 'steps.ckpt'; %segmentation model. Options: ideas.ckpt, steps.ckpt, stiv.ckpt, steps2.yaml
PA.Classif = 'iv_ccec.mat'; %iv system file name. Options:  'iv_ccec.mat', 'iv_ccec_matlab.mat'
PA.ClassifGen = 'knn_steps.mat'; %classifier generic child vs teacher. Options:  'knn_ccec.mat', 'knn_pk.mat', 'knn_steps', 'knn_steps_mat' (with iv_ccec_matlab) Empty if no general classif needed
PA.ClassifFocC = []; %classifier generic focal child. Options:  'knn_pk_focal_child.mat' Empty if no focal classif needed
PA.ClassifFocT = []; %% classifier generic focal teacher. Options: 'knn_pk_focal_teacher.mat';


%%%% Measures
PA.Cd = 5*60; %batch duration


