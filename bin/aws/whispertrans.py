#!/usr/bin/python
from __future__ import print_function
import time
import sys
import json
import whisper

def main():
    
    job_name = sys.argv[1]


    local_file = job_name +".wav"

    # Transcribe audio file
    model_name = "medium.en" 
    model = whisper.load_model(model_name)
    output = model.transcribe(local_file,word_timestamps=True)
    with open (job_name+".json", "w") as FILE:
        FILE.write(json.dumps(output, indent=4))    


if __name__ == '__main__':
    main()