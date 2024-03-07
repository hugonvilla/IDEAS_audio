function [Y,Trc] = Lmeasures(GTxj)
%%% input string vector
opts = spreadsheetImportOptions("NumVariables", 1);
opts.VariableNames = "CommonWords";
opts.VariableTypes = "string";
CommonWord = readmatrix(fullfile(pwd,'bin','AcademicMasterListRareWord.xlsx'), opts, "UseExcel", false);
CommonWord(1,:)=[];
CommonWord = lower(CommonWord);

PA = parameters();

GT_t = string(GTxj);
%%%%%% Frequency variables
if any(~strcmp(GT_t,"")) %if non-empty strings
    Y.FU = size(GTxj,1);  %number of utterances
else
    Y.FU=0;
end
GT_t = rmmissing(GT_t);
Tr = strsplit(join(GT_t)); %convert to list of words
Tr = erase(Tr,["xxx","xx","x"]);
Trc = convertStringsToChars(Tr);

if PA.Tokenizer == "spacy"
    % Define the CSV file path
    if isunix
        csvPath = 'bin/spacy/temp_csv.csv';
    else
        csvPath = 'bin\spacy\temp_csv.csv';
    end

    % Write the data to the CSV file
    writematrix(GT_t, csvPath, 'Delimiter', ',');

    % Call the Spacy tokenizer
    if isunix
        system('cd bin/spacy; python spacy_tokenizer.py');
    else
        system('cd bin\spacy & python spacy_tokenizer.py');
    end

    opts = detectImportOptions(csvPath);
    opts.VariableNamingRule = 'preserve';

    dataTable = readtable(csvPath, opts);
    Y.FW = dataTable.FW; %number of words
    Y.FV = dataTable.FV; %number of verbs
    Y.FA = dataTable.FA; %number of auxiliary verbs
    Y.FC = dataTable.FC; %coordinating conjunction
    Y.FS = dataTable.FS; %subordinating conjunction
    Y.FJ = dataTable.FJ; %number of adjectives
    Y.FN = dataTable.FN; %unique words
    Y.FR = dataTable.FR; %Number of rare words: unique words - common words

elseif PA.Tokenizer == "matlab"
    Tostr = tokenizedDocument(Tr); %tokenized string
    Tostr = addPartOfSpeechDetails(Tostr);

    if isempty(tokenDetails(Tostr)) == 0
        Y.FW = size(tokenDetails(Tostr),1); %number of words
        Y.FV = numel(find(tokenDetails(Tostr).PartOfSpeech=='verb')); %number of verbs
        Y.FA = numel(find(tokenDetails(Tostr).PartOfSpeech=='auxiliary-verb')); %number of auxiliary verbs
        Y.FC = numel(find(tokenDetails(Tostr).PartOfSpeech=='coord-conjunction')); %coordinating conjunction
        Y.FS = numel(find(tokenDetails(Tostr).PartOfSpeech=='subord-conjunction')); %subordinating conjunction
        Y.FJ = numel(find(tokenDetails(Tostr).PartOfSpeech=='adjective')); %number of adjectives
        Y.FN = numel(Tostr.Vocabulary); %unique words
        Y.FR = Y.FN-numel(find(ismember(Tostr.Vocabulary,CommonWord))); %Number of rare words: unique words - common words
    else
        Y.FW=0; Y.FV = 0; Y.FA=0;Y.FC=0; Y.FS=0; Y.FJ=0;Y.FN=0;Y.FR=0;
    end
end

%%%%%% RATE variables
if Y.FU~=0
    Y.RWU = Y.FW/Y.FU; %rate of number of words per number of utterance
else
    Y.RWU = 0;
end
if Y.FW~=0
    Y.RNW = Y.FN/Y.FW; %rate of unique words per number of words
else
    Y.RNW = 0;
end
Y = struct2table(Y);

end






