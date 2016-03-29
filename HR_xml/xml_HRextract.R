#Load XML for HR Data
require(XML)

#set the directory to XML folder
setwd("C:/Users/Seth/workspace/R workspace/HR_xml/")

#get list off all xml files
xml_files<-list.files(path = ".", pattern='*.xml')

#initialize dataframes
hrDF=data.frame()
temp_trialDF=data.frame()

#cycle through xml files
for (xml_file in xml_files){
  #parse filename information
  filename=xml_file
  file_info=unlist(strsplit(filename,'_'))
  date=file_info[1]
  #temp_trialDF$trial_id=substr(filename,1,nchar(filename)-4)
  temp_trialDF=data.frame(date)
  temp_trialDF$time=file_info[2]# is this right?
  temp_trialDF$subject=file_info[3]
  temp_trialDF$vacuum=file_info[4]
  temp_trialDF$condition=file_info[5]
  temp_trialDF$trial_number=substr(file_info[6],1,nchar(file_info[6])-4)
  
  #create xml tree
  xmlTree <- xmlTreeParse(filename, getDTD = F)
  node <- xmlRoot(xmlTree)
  
  #get time from xmltree 
  temp_trialDF$record_time=xmlValue(node[['calendar-items']][['exercise']][['time']])
  
  #create result_node for indexing that branch more dirrectly
  result_node=node[['calendar-items']][['exercise']][['result']]
  temp_trialDF$samples_str=xmlValue(result_node[['samples']][['sample']][['values']])
  temp_trialDF$maxHR=as.numeric(xmlValue(result_node[['heart-rate']][['maximum']]))
  temp_trialDF$avgHR=as.numeric(xmlValue(result_node[['heart-rate']][['average']]))
  temp_trialDF$recording_rate=as.numeric(xmlValue(result_node[['recording-rate']]))
  temp_trialDF$duration_str=xmlValue(result_node[['duration']])
  temp_trialDF$duration_secs=as.numeric(difftime(strptime(temp_trialDF$duration_str, format='%H:%M:%S'),strptime("00:00:00.000", format='%H:%M:%S'), units='secs'))
  
  hr_values<-as.numeric(unlist(strsplit(temp_trialDF$samples_str,',')))
  temp_trialDF$calc_maxHR=max(hr_values)
  temp_trialDF$calc_minHR=min(hr_values)
  temp_trialDF$calc_avgHR=mean(hr_values)
  temp_trialDF$calc_AUCHR=sum(hr_values)#area under the curve
  temp_trialDF$calc_rangeHR=temp_trialDF$calc_maxHR-temp_trialDF$calc_minHR
  
  #join with all subjects DF
  hrDF<-rbind(hrDF,temp_trialDF)
  
}

#To look at the HR compared on certain conditions may want to use cast, creates a pivot table type output
require(reshape)
# get the max heartrate for subject's max heart rate for each of the vacuum conditions under full condition
max_heartrate_compare=cast(hrDF[hrDF$condition=='full',], subject~vacuum, value='maxHR')
