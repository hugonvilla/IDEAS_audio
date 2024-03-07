#!/usr/bin/python
from __future__ import print_function
import time
import boto3
import sys
import json

def main():
    
    job_name = sys.argv[1]

    # Upload audio file to S3
    s3 = boto3.client('s3')


    local_file = job_name +".wav"
    bucket = "steps2audio"
    s3_file = local_file
    s3.upload_file(local_file, bucket, s3_file)

    # Transcribe audio file
    transcribe = boto3.client('transcribe')
    job_uri= "s3://"+bucket+"/"+local_file

    transcribe.start_transcription_job(
        TranscriptionJobName=job_name,
        Media={'MediaFileUri': job_uri},
        MediaFormat='wav',
        LanguageCode='en-US',
        MediaSampleRateHertz= 16000,
        OutputBucketName=bucket,
        #ModelSettings={'LanguageModelName':'PKClassroom'},
        Settings={'MaxSpeakerLabels': 4,'ShowSpeakerLabels': True}
    )
    while True:
        status = transcribe.get_transcription_job(TranscriptionJobName=job_name)
        if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
            break
        print("Not ready yet...")
        time.sleep(5)
    print(status) 

    if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED']:
        #Download file
        s3_down = job_name + ".json"
        down_name = s3_down
        s3.download_file(bucket, s3_down,down_name)
    else:
        FailReason = status['TranscriptionJob']['FailureReason']
        with open(job_name +"_fail.json", 'w') as outfile:
            json.dump(FailReason, outfile)


    #Delete files and jobs
    response = s3.delete_object(
        Bucket=bucket,
        Key=down_name
    )

    response2 = s3.delete_object(
        Bucket=bucket,
        Key=s3_file
    )

    #delete job
    transcribe.delete_transcription_job(TranscriptionJobName=job_name)



if __name__ == '__main__':
    main()