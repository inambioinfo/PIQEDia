#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = T)
#a2<-parse(text=paste(commandArgs(trailingOnly = TRUE), collapse=";"))
#?parse

args<-gsub("\\\\","/",args)
print("input arguments")
print("______________________")
print(args)
#args<-c("C:\\test_this","C:\\two\\examples.csv")


##################################################################################################################
############### helper function #1
#############################################
####################################################################################


mod.pos.protein=function(table=rawtable,mass="[+100]"){
  
  pep.start.pos<-table[,"Begin.Pos"]
  #table<-table[pep.start.pos!="#N/A",]
  #pep.start.pos<-pep.start.pos[pep.start.pos!="#N/A"]
  
  protein.names<-table[,"uniprot"]
  pep.charseq<-as.character(table[,"Peptide.Modified.Sequence"])
  num.peps<-length(pep.start.pos)
  pep.pos.list<-lapply(FUN=mod.position.pep, pep.charseq, modmass=mass)
  prot.pos.list<-list()
  prot.pos.vec<-rep(0,times=num.peps)
  
  #### loop through the pep.pos.list
  #### add those numbers to the number in pep.start.pos
  #### put those numbers in named list
  
  #### make empty list with names of slots
  for(i in 1:num.peps){
    prot.pos.list[[as.character(protein.names[i])]]<-c()
  }
  
  for(i in 1:num.peps){
    prot.pos.list[[as.character(protein.names[i])]]<-c(prot.pos.list[[as.character(protein.names[i])]],as.numeric(as.character(pep.start.pos[i]))+pep.pos.list[[i]])
    tempmods<-as.numeric(as.character(pep.start.pos[i]))+pep.pos.list[[i]]
    if(length(tempmods)>1){
      
      prot.pos.vec[i]<-paste(tempmods,sep="_",collapse="_")
    }
    if(length(tempmods)==1){
      prot.pos.vec[i]<-tempmods
    }
    #prot.pos.vec[i]<-as.numeric(as.character(pep.start.pos[i]))+pep.pos.list[[i]]
  }
  #names(prot.pos.list)->loopthrou
  #for(x in loopthrou){
  #	prot.pos.list[[x]]<-unique(prot.pos.list[[x]])
  #	}
  #rawtable[1:5,1:7]
  newtable<-cbind(prot.pos.vec,table)
  #newtable[1:5,1:10]
  return(newtable)
}


##################################################################################################################
############### helper function #2
#############################################
####################################################################################


mod.position.pep=function(charseq="GK[+42]GK[+42]GQK[+42]R",modmass="[+42]"){
  regexpr(charseq,pat="(\\[)")
  string.len<-nchar(charseq)
  modopenbracket<-gregexpr(charseq,pattern="(\\[)")[[1]]
  num.mods<-length(modopenbracket)
  modclosebracket<-gregexpr(charseq,pattern="(\\])")[[1]]
  mod.string.len<-modclosebracket-modopenbracket+1
  mod.pos.string<-modopenbracket
  mod.pos.pep<-list()
  mod.pos.pep[[1]]<-modopenbracket[1]-1
  if(num.mods>=2){
    for(i in 2:num.mods){
      mod.pos.pep[[i]]<-mod.pos.string[[i]]-mod.string.len[[i-1]]*(i-1)-1
    }
  }
  modmasses<-list()
  for(i in 1:num.mods){
    modmasses[[i]]<-substr(charseq,start=modopenbracket[i],stop=modclosebracket[i])
  }
  which(unlist(modmasses)==modmass)
  return(unlist(mod.pos.pep[which(unlist(modmasses)==modmass)]))	
  #pep<-gsub("([)([0-9]+)(.)([0-9]+)(])", replacement="", charseq) 
}

##################################################################################################################
############### helper function #3
#############################################
####################################################################################


protlvlcorrection = function(sitelevels=mapDIAinput, proteinlevels="proteinlevels.txt",params="C:/urineALL/mapDIA.params",dir="C:/urineALL/"){
  #head(mapDIAinput)
  #### run names must be in the same order for both matricies
  setwd(dir)
  sl<-sitelevels
  sitelvl.proteins<-substr(sitelevels[,1],start=1, stop=6)
  sl<-cbind(sitelvl.proteins,sl)
  head(sl)
  #sitelvl.unique.prot<-unique(proteins)
  
  pl<-read.delim(proteinlevels,header = T,stringsAsFactors = F)
  protlvl.proteins<-substr(pl[,1],start=1, stop=6)
  
  #### match the site level columns to the correct protein level columns
  pl.colnames<-names(pl)
  sl.colnames<-names(sl)
  sl.areacols<-grep("Area",sl.colnames)
  pos.in.pl<-match(sl.colnames[sl.areacols],pl.colnames)
  pl<-pl[,c(1,pos.in.pl)]
  ### add 1 to each value to ensure no /0
  pl[,2:ncol(pl)]<-pl[,2:ncol(pl)]+1
  
  #matches<-match(sitelvl.unique.prot,protlvl.proteins)
  #check order at some point
  #nchar(names(sl)[grep("X",names(sl))])
  names(sl)[grep("Area",names(sl))] <- paste(names(sl)[grep("Area",names(sl))], "site", sep=" ")
  names(pl)[grep("Area",names(pl))] <- paste(names(pl)[grep("Area",names(pl))], "total", sep=" ")
  names(sl)[1]<-"uniprot"
  names(pl)[1]<-"uniprot"
  merged <- merge(sl,pl,by.x=1,by.y=1)
  head(merged)
  m.mod <- as.matrix(merged[,grep(" site", names(merged))])
  m.mod <-apply(m.mod, 2, as.numeric)
  m.tot <- as.matrix(merged[,grep(" total", names(merged))])
  m.tot  <-apply(m.tot , 2, as.numeric)
  normalized <- m.mod/m.tot
  head(normalized)
  rn<-merged[,c("uniprot_site", "Peptide.Modified.Sequence", "Product.Mz")]
  normalized.final <- cbind(rn, normalized,RT=merged[,"RT"])
  head(normalized.final)
  #fileout=paste(dir,"mapDIA_input.txt",sep="",col="")
  normalized.final[normalized.final=="Inf"]<-"NA"
  #write.table(file=fileout,normalized.final,row.names = F,quote=F,sep="\t")
  normalized.final
}


################## little helper function

get.labels=function(con="C:/urineALL/mapDIA.parameters"){
  lines<-readLines(con)
  label.line<-grep("LABELS=",lines)
  label.vec<-unlist(strsplit(lines[label.line],split=" "))
  label.vec<-label.vec[2:length(label.vec)]
  return(label.vec)
}




##################################################################################################################
############### main function 
#############################################
####################################################################################

#ptmProphName ="C:/urineALL/ptmProphet-output-file.ptm.pep.xml"
prepMapDIAin=function(ptmProphName = "", 
                            skyline.output= "C:/BAT/2016_0826_mapDIA_succinyl.csv", 
                            ptm.score=0.95,
                            modstring= "K100,K42",
                            wd="C:/BAT/",
                            namemapping=nm,
                            protlvl.correction=TRUE)
  {
  setwd(wd)
  
  #### read in skyline file, reformat, check which lines are significant in the ptmprophet
  #### alternately, this could be done as a connection instead of into memory
  print("reading skyline report")
  skyline.raw<-read.csv(skyline.output,stringsAsFactors = F,header = T)
  modmass<-as.numeric(gsub("[A-Z]", "", modstring))
  modmass4sky<-paste("+",round(modmass),collapse = "",sep="")
  modmass4reformat<-paste("[","+",round(modmass),"]",collapse = "",sep="")
  unique.peps<-unique(skyline.raw[,1])
  mod.peps.full<-unique.peps[grepl(unique.peps,pattern=modmass4sky)]
  mod.peps.cleaned<-gsub("(\\[)[-+][0-9]+(\\])","",mod.peps.full)
  nmods<-sapply(regmatches(mod.peps.full, gregexpr(modmass4sky, mod.peps.full)), length)
  skyline.mod.results.summary<-data.frame(mod.peps.full,mod.peps.cleaned,nmods)
  

  
  if(nchar(ptmProphName)>7){    #### check if there was a real pep.xml file input
    ### check for xml package otherwise install
    if(library(XML,logical.return=T)==FALSE) install.packages("XML")
    if(library(XML, logical.return = T)==TRUE) require(XML)
    print("using PTMprophet localization filter")
    doc<-xmlParse(ptmProphName)
    ptm.score<-as.numeric(ptm.score)
    namespaces<-c(ns="http://regis-web.systemsbiology.net/pepXML")
    tides = unlist(xpathApply(doc, "//ns:ptmprophet_result[@ptm='PTMProphet_STY79.966']", xmlGetAttr, "ptm_peptide", namespaces = namespaces ))
    cleaned<-sapply(FUN=gsub,"([(])([0-9])(.)([0-9]+)())",x=tides,replacement="")
    probstrings<-gsub("[A-Z]+", "", tides)
    probstr.a<-strsplit(probstrings,split="[\\)\\(]")
    for(i in 1:length(probstr.a)){
      probstr.a[[i]]<-probstr.a[[i]][nchar(probstr.a[[i]])>0]
    }
    
    probstr<-lapply(FUN=as.numeric,probstr.a)
    probsumlist<-lapply(FUN=sum,probstr)
    ptms.localized<-rep(0,times=length(probstr))
    for(i in 1:length(probstr)){
      ptms.localized[i]<-length(which(probstr[[i]]>ptm.score))==round(probsumlist[[i]],digits=0)
      #probsumlist[[i]]
    }
    ptm.localized.summary<-data.frame(peptide.full=tides,pep.cleaned=cleaned,is.localized=ptms.localized)
    ptm.localized.true<-ptm.localized.summary[ptm.localized.summary[,3]==1,]
    #nrow(ptm.localized.true)
    #head(ptm.localized.true)
    #ptm.localized.true[is.na(match(ptm.localized.true[,2],skyline.mod.results.summary[,2])),]
    skyline.localized<-skyline.mod.results.summary[is.na(match(skyline.mod.results.summary[,2],ptm.localized.true[,2]))==FALSE,]
    keep<-as.character(skyline.localized[,1])
    skyline.filtered<-skyline.raw[is.na(match(skyline.raw[,1],keep))==FALSE,]
  }
  
  if(nchar(ptmProphName)<7){      ### if the PTMprophet file not given, just rename skyline data.frame
    skyline.filtered<-skyline.raw[is.na(match(skyline.raw[,1],mod.peps.full))==FALSE,]
  }
  
  ### reformat filtered report
  proteins<-substr(start=4,stop=9,x=skyline.filtered[,"Protein"])
  s<-cbind(uniprot=proteins,skyline.filtered)
  
  
  
  
  #### check that modstring is appropriate
  ################
  s.pos<-multimod.pos.protein(table=s,mass=modmass4reformat)
  names(s.pos)[1] <- "site"
  s.unisite <- paste(s.pos[,"uniprot"], s.pos[,"site"], sep="_")  
  s.uni<-cbind(s.unisite,s.pos)
  names(s.uni)[1] <- "uniprot_site"
  area.columns<-grep("Area",names(s.uni))
  RTcol<-grep("Average.Measured.Retention.Time",names(s.uni))
  m.temp1<-s.uni[,c("uniprot_site","Peptide.Modified.Sequence","Product.Mz")]
  tmp<-cbind(m.temp1,s.uni[,area.columns])
  #m.temp2<-s.uni[,c(area.columns,RTcol)]
  mapDIAinput<-cbind(tmp,s.uni[,RTcol])
  names(mapDIAinput)[length(names(mapDIAinput))]<-"RT"
  #head(mapDIAinput)
  #write.csv(skyline.mod.results.summary,file="C:/skylineModResultsSummary.csv",row.names = F, quote=F)
  #### write the output file
  #### currently this just tests that it can be written need to re-format
  #colnames(cleaned)<-"peptide.sequence"
  #data.frame(peptides=cleaned,is.localized=ptms.localized)
  
  #write.csv(data.frame(pep.cleaned=cleaned,is.localized=ptms.localized),file="C:/testRoutput.csv",row.names = F, quote=F)
  mapDIAinput[mapDIAinput=="#N/A"]<-"NA"
  names(mapDIAinput)[length(names(mapDIAinput))]<-"RT"
  

  #### with protein level correction
  if(protlvl.correction==TRUE){
    print("correcting protein levels")
    mapDIAinput<-protlvlcorrection(sitelevels=mapDIAinput, proteinlevels="proteinlevel.txt",dir=wd)
  }
  
  ##### finally, assign name mapping table if provided
  ################################################################################
  ### reorder area columns by group
  
  
  ### if namemapping file exists, replace columns with group headers
  if(namemapping==TRUE){
    namemap<-read.delim("name_mapping.txt",header = T,stringsAsFactors = F,colClasses = "character")
    n.groups<-ncol(namemap)
    groups<-colnames(namemap)
    for(x in groups){
      tmp.grp.nm<-namemap[,x][nchar(namemap[,x])>1]
      grp.cols<-grep(paste(tmp.grp.nm,sep="|",collapse = "|"), colnames(mapDIAinput))
      i=1
      for(y in grp.cols){
        colnames(mapDIAinput)[y]<-paste(x,i,sep = ".")
        i=i+1
      }
    }
  }
  

  groups<-get.labels(con=paste(wd,"mapDIA.parameters",collapse="",sep=""))
  head(mapDIAinput)
  tmp<-mapDIAinput[,1:3]
  for(i in 1:length(groups)){
    print(i)
     tmp<-cbind(tmp,mapDIAinput[,grep(paste(groups[i],"",sep="."),names(mapDIAinput),fixed=T,value=T)])
  }
  head(tmp)
  tmp<-cbind(tmp,"RT"=mapDIAinput[,"RT"])
  
  finalout<-tmp
  #### without protein level correction

  print("writing mapDIA input file")
  fileout<-paste(wd,"mapDIA_Input.txt",sep="",collapse = "")
  write.table(file=fileout, finalout,row.names = F,quote=F,sep="\t")
  #return(mapDIAinput)
}

#prepMapDIAin()


############################################################################
##### actually do stuff here
#############################################################################################
setwd(args[5])
#setwd("C:/urineALL/")
#getwd()
#### check for name mapping file exist, if so, fix column names to name map
nameMapFile<-list.files(pattern="name_mapping.txt")
nm=FALSE
if(length(nameMapFile)==1){
  print("condition name mapping file available")
  nm=TRUE
}
#### check if protein level quantification file exists, and if so, correct files to protein level
protlvlfile<-list.files(pattern="proteinlevels.txt")
correct=FALSE
if(length(protlvlfile)==1){
  print("protein levels available")
  correct=TRUE
}


if(length(args)<5) print("missing arguments to command line")
if(length(args)==5){
  print("starting R...")
  prepMapDIAin(ptmProphName=args[1],skyline.output=args[2],ptm.score = args[3],modstring= args[4], wd=args[5],protlvl.correction = correct)
}



#prepMapDIAin(ptmProphName = "C:/urine_test2/ptmProphet-output-file.ptm.pep.xml",skyline.output = "C:/urine_test2/2016_0826_mapDIA.csv", wd = "C:/urine_test2/", protlvl.correction = FALSE)



