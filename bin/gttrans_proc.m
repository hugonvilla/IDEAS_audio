function annot = gttrans_proc(annot)
    annot = eraseBetween(annot,"[","]",'Boundaries','inclusive');
    %annot = eraseBetween(annot,"(",")",'Boundaries','inclusive');
    annot = erase(annot,["<",">",":","="]);
    annot(contains(annot,'&'))="";
    annot = strrep(annot,'_',' '); %replace _ with blank space
    annot = erasePunctuation(annot);
    annot(ismissing(annot)) = "";
    annot = lower(annot);
    %annot(strcmp(annot,""))=[];