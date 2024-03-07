from __future__ import print_function
import time
import boto3
import json

job_name = "temp14"

# Transcribe audio file
transcribe = boto3.client('transcribe')

status = transcribe.get_transcription_job(TranscriptionJobName=job_name)

if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED']:
    print("yes")
else:
    FailReason = status['TranscriptionJob']['FailureReason']
    with open(job_name +"_fail.json", 'w') as outfile:
        json.dump(FailReason, outfile)
