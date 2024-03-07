
function TEL = ELAN_process(Tpath,Chnum)

%%%% ELAN options
opts = delimitedTextImportOptions("NumVariables", 6);
opts.Delimiter = "\t";
opts.VariableTypes = ["categorical", "string", "double", "double", "double", "string"];
opts.VariableNames = ["tier", "Var2", "onset", "offset", "duration", "trans"];

TEL = readtable(Tpath,opts);
TEL.Var2=[]; %not using ELAN comments
TEL.duration=[]; %not using ELAN duration

TEL(contains(string(TEL.tier),'aux'),:)=[];
%TEL(contains(string(TEL.tier),'No'),:)=[];
%TEL(contains(string(TEL.tier),'MULTIALL'),:)=[];


%%%%% 
if ismember('SLP',TEL.tier)
    TEL.tier = renamecats(TEL.tier,'SLP',"T00");
end
if ismember('SLP02',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'T00','SLP02'});
end
if ismember('EE1',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'T00','EE1'});
end
if ismember('EEL',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'T00','EEL'});
end

if any(contains(string(TEL.tier),'CH')) %CHI or NCHI for now. Later, we should replace with S99 for focal child
    Idc = find(contains(string(TEL.tier),'CH'));
    TEL.tier = mergecats(TEL.tier,string(unique(TEL.tier(Idc))),"S00");
end

if ismember('MULTIALL',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'S00','MULTIALL'});
end


if ismember('Focal_Child',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'Focal_Child','No_Focal_Child'});
    TEL.tier = renamecats(TEL.tier,'Focal_Child',Chnum);
elseif ismember('Focal_Teacher',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'Focal_Teacher','No_Focal_Teacher'});
    TEL.tier = renamecats(TEL.tier,'Focal_Teacher',Chnum);
end

if ismember('Peer',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'Peer','No_Peer'});
    TEL.tier = renamecats(TEL.tier,'Peer','S00');
end
if ismember('Teacher',TEL.tier)
    TEL.tier = mergecats(TEL.tier,{'Teacher','No_Teacher'});
    TEL.tier = renamecats(TEL.tier,'Teacher','T00');
end

TEL= sortrows(TEL,"onset");
TEL.Properties.VariableNames{strcmp(TEL.Properties.VariableNames,'tier')} = 'spkid';
TEL.Properties.VariableNames{strcmp(TEL.Properties.VariableNames,'onset')} = 'start_a';
TEL.Properties.VariableNames{strcmp(TEL.Properties.VariableNames,'offset')} = 'end_a';

%%%%% generate speaker type variable
TEL.spkid(find(ismissing(TEL.spkid))) = "S00";
TEL.spk_type = TEL.spkid;
Sidx = (contains(string(TEL.spkid),'S') & (TEL.spkid ~= Chnum)); %peer IDs indices
TEL.spk_type = mergecats(TEL.spk_type,string(unique(TEL.spk_type(Sidx))),"S00");
Tidx = (contains(string(TEL.spkid),'T') & (TEL.spkid ~= Chnum)); %teacher IDs indices
TEL.spk_type = mergecats(TEL.spk_type,string(unique(TEL.spk_type(Tidx))),"T00");

if ismember(Chnum,TEL.spk_type)
    if contains(Chnum,'T')
        TEL.spk_type = renamecats(TEL.spk_type,Chnum,"T99");
    else
        TEL.spk_type = renamecats(TEL.spk_type,Chnum,"S99");
    end
end

TEL.trans(ismissing(TEL.trans))="[]";

%%%%% process transcript
for kk = 1:size(TEL,1)
    %pid = extractBetween(TEL.trans(kk),'[',']');
    pid=""; %when no info is in between brackets
    if ~isempty(pid)
        TEL.pid(kk) = pid;
        TEL.trans(kk) = eraseBetween(TEL.trans(kk),'[',']','Boundaries','inclusive');
    else
        TEL.pid(kk) = "";
    end
end
TEL.trans = gttrans_proc(TEL.trans);
Inmp = find(~strcmp(TEL.pid,""));
TEL.spkid(Inmp) = categorical(TEL.pid(Inmp)); %replace with proximal

TEL.trans = eraseBetween(TEL.trans,'[',']','Boundaries','inclusive');
TEL.nw = arrayfun(@(x) numel(split(x)), TEL.trans);
TEL.nw(ismissing(TEL.trans) | strcmp(TEL.trans,"")) = 0;