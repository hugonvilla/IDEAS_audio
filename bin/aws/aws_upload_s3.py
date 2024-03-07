#!/usr/bin/python
from __future__ import print_function
import time
import boto3
import sys

def main():
    
    local_file  = sys.argv[1]

    s3 = boto3.client('s3')
    bucket = "lyle2audio"
    # Upload audio file to S3
    s3.upload_file(local_file, bucket, local_file)


if __name__ == '__main__':
    main()